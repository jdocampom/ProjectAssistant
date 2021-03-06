//
//  ProjectsView.swift
//  My Portfolio
//
//  Created by Juan Diego Ocampo on 18/03/22.
//

import SwiftUI

struct ProjectsView: View {
    
    static let openTag: String? = "Open"
    static let closedTag: String? = "Closed"
    
    @StateObject var viewModel: ViewModel
    
    @State private var showingSortOrder = false
    
    var projectsList: some View {
        Group {
            List {
                ForEach(viewModel.projects) { project in
                    Section(header: ProjectHeaderView(project: project)) {
                        ForEach(project.projectItems(using: viewModel.sortOrder)) { item in
                            ItemRowView(project: project, item: item)
                        }
                        .onDelete { viewModel.delete($0, from: project) }
                        if !viewModel.showClosedProjects {
                            Button {
                                withAnimation {
                                    viewModel.addItem(to: project)
                                }
                            } label: {
                                Label("Add New Item", systemImage: "plus")
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            SelectSomethingView()
        }
        .sheet(isPresented: $viewModel.showingUnlockView) {
            UnlockView()
        }
    }
    
    var addProjectToolbarButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if !viewModel.showClosedProjects {
                Button {
                    withAnimation {
                        viewModel.addProject()
                    }
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            }
        }
    }
    
    var sortItemsToolbarButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { showingSortOrder.toggle() } label: {
                Label("Sort Items", systemImage: "arrow.up.arrow.down")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.projects.isEmpty {
                    Text("There are no projects yet").foregroundColor(.secondary)
                } else {
                    projectsList
                }
            }
            .navigationTitle(viewModel.showClosedProjects ? "Closed Projects" : "Open Projects")
            //            .background(Color.systemGroupedBackground.ignoresSafeArea())
            .toolbar {
                addProjectToolbarButton
                sortItemsToolbarButton
            }
            .actionSheet(isPresented: $showingSortOrder) {
                ActionSheet(title: Text("Sort Items"), message: nil, buttons: [
                    .default(Text("Automatic")) { viewModel.sortOrder = .optimized },
                    .default(Text("Creation Date")) { viewModel.sortOrder = .creationDate },
                    .default(Text("Title")) { viewModel.sortOrder = .title },
                    .cancel()
                ])
            }
            .onOpenURL(perform: openURL)
        }
    }
    
    init(dataController: DataController, showClosedProjects: Bool) {
        let viewModel = ViewModel(dataController: dataController, showClosedProjects: showClosedProjects)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    func openURL(_ url: URL) {
        viewModel.addProject()
    }
    
}

struct ProjectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectsView(dataController: DataController.preview, showClosedProjects: false)
    }
}
