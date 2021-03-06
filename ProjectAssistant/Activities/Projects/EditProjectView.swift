//
//  EditProjectView.swift
//  My Portfolio
//
//  Created by Juan Diego Ocampo on 21/03/22.
//

import CloudKit
import CoreHaptics
import SwiftUI

struct EditProjectView: View {
    
    enum CloudStatus {
        case checking, exists, absent
    }
    
    @State private var cloudStatus = CloudStatus.checking
    @State private var cloudError: CloudError?
    
    private let colorColumns = [GridItem(.adaptive(minimum: 44))]
    
    @AppStorage("username") var username: String?
    @State private var showingSignIn = false
    
    @ObservedObject var project: Project
    
    @EnvironmentObject var dataController: DataController
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingDeleteConfirm = false
    @State private var title: String
    @State private var detail: String
    @State private var color: String
    
    @State private var remindMe: Bool
    @State private var reminderTime: Date
    
    @State private var engine = try? CHHapticEngine()
    @State private var showingNotificationsError = false
    
    var body: some View {
        let message1 = "Closing a project moves it from the Open to Closed tab."
        let message2 = "Deleting it removes the project and any items it contains completely."
        let alertMessage1 = "Are you sure you want to delete this project?"
        let alertMessage2 = "By doing so, you will also delete all the items it contains."
        return Form {
            Section(header: Text("Project Settings")) {
                TextField("Name", text: $title.onChange(update))
                TextField("Description", text: $detail.onChange(update))
            }
            Section(header: Text("Color Label")) {
                LazyVGrid(columns: colorColumns) {
                    ForEach(Project.colors, id: \.self, content: colorButton)
                }
                .padding(.vertical)
            }
            Section(header: Text("Project Reminders")) {
                Toggle("Enable Notifications", isOn: $remindMe.animation().onChange(update))
                    .alert(isPresented: $showingNotificationsError) {
                        Alert(
                            title: Text("Oops!"),
                            message: Text("There was a problem. Please check you have notifications enabled."),
                            primaryButton: .default(Text("Check Settings"), action: showAppSettings),
                            secondaryButton: .cancel()
                        )
                    }
                if remindMe {
                    DatePicker("Reminder Time",
                               selection: $reminderTime.onChange(update),
                               displayedComponents: .hourAndMinute)
                }
            }
            Section(footer: Text("\(message1) \(message2)")) {
                Button(project.completed ? "Reopen this Project" : "Close this Project", action: toggleClosed)
                Button("Delete this Project") {
                    showingDeleteConfirm.toggle()
                }
                .accentColor(.red)
                .alert(isPresented: $showingDeleteConfirm) {
                    Alert(
                        title: Text("Delete Project"),
                        // swiflint:disable:next line_length
                        message: Text("\(alertMessage1) \(alertMessage2)"),
                        primaryButton: .default(Text("Delete"), action: delete),
                        secondaryButton: .cancel()
                    )
                }
            }
        }
        .navigationTitle("Edit Project")
        .sheet(isPresented: $showingSignIn, content: SignInView.init)
        .toolbar {
            switch cloudStatus {
            case .checking:
                ProgressView()
            case .exists:
                Button {
                    removeFromCloud(deleteLocal: false)
                } label: {
                    Label("Remove from iCloud", systemImage: "icloud.slash")
                }
            case .absent:
                Button(action: uploadToCloud) {
                    Label("Upload to iCloud", systemImage: "icloud.and.arrow.up")
                }
            }
        }
        .onAppear(perform: updateCloudStatus)
        .onDisappear(perform: dataController.save)
        .alert(item: $cloudError) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message)
            )
        }
    }
    
    init(project: Project) {
        self.project = project
        _title = State(wrappedValue: project.projectTitle)
        _detail = State(wrappedValue: project.projectDetail)
        _color = State(wrappedValue: project.projectColor)
        if let projectReminderTime = project.reminderTime {
            _reminderTime = State(wrappedValue: projectReminderTime)
            _remindMe = State(wrappedValue: true)
        } else {
            _reminderTime = State(wrappedValue: Date())
            _remindMe = State(wrappedValue: false)
        }
    }
    
}

extension EditProjectView {
    
    func update() {
        project.title = title
        project.detail = detail
        project.color = color
        if remindMe {
            project.reminderTime = reminderTime
            dataController.addReminders(for: project) { success in
                if success == false {
                    project.reminderTime = nil
                    remindMe = false
                    
                    showingNotificationsError = true
                }
            }
        } else {
            project.reminderTime = nil
            dataController.removeReminders(for: project)
        }
    }
    
    func delete() {
        if cloudStatus == .exists {
            removeFromCloud(deleteLocal: true)
        } else {
            dataController.delete(project)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func toggleClosed() {
        project.completed.toggle()
        update()
        do {
            try? engine?.start()
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
            let start = CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1)
            let end = CHHapticParameterCurve.ControlPoint(relativeTime: 1, value: 0)
            let parameter = CHHapticParameterCurve(parameterID: .hapticIntensityControl,
                                                   controlPoints: [start, end],
                                                   relativeTime: 0)
            let event1 = CHHapticEvent(eventType: .hapticTransient,
                                       parameters: [intensity, sharpness],
                                       relativeTime: 0)
            let event2 = CHHapticEvent(eventType: .hapticContinuous,
                                       parameters: [intensity, sharpness],
                                       relativeTime: 0.125,
                                       duration: 1)
            let pattern = try CHHapticPattern(events: [event1, event2], parameterCurves: [parameter])
            let player = try? engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    func colorButton(for item: String) -> some View {
        ZStack {
            Color(item)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(6)
            if item == color {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
        }
        .onTapGesture {
            color = item
            update()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(item == color ? [.isButton, .isButton] : .isButton)
        .accessibilityLabel(LocalizedStringKey(item))
    }
    
    func showAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func uploadToCloud() {
        if let username = username {
            let records = project.prepareCloudRecords(owner: username)
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            operation.savePolicy = .allKeys
            operation.modifyRecordsCompletionBlock = { _, _, error in
                if let error = error {
                    cloudError = error.getCloudKitError()
                }
                updateCloudStatus()
            }
            cloudStatus = .checking
            CKContainer.default().publicCloudDatabase.add(operation)
        } else {
            showingSignIn = true
        }
    }
    
    func updateCloudStatus() {
        project.checkCloudStatus { exists in
            if exists {
                cloudStatus = .exists
            } else {
                cloudStatus = .absent
            }
        }
    }
    
    func removeFromCloud(deleteLocal: Bool) {
        let name = project.objectID.uriRepresentation().absoluteString
        let id = CKRecord.ID(recordName: name)
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [id])
        operation.modifyRecordsCompletionBlock = { _, _, error in
            if let error = error {
                cloudError = error.getCloudKitError()
            } else {
                if deleteLocal {
                    dataController.delete(project)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            updateCloudStatus()
        }
        cloudStatus = .checking
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
}

struct EditProjectView_Previews: PreviewProvider {
    static var previews: some View {
        EditProjectView(project: Project.example)
    }
}
