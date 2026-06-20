import SwiftUI

struct MenuBarView: View {
    @Environment(ContainerManager.self) private var manager
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(String(localized: "menu.system_status \(manager.systemStatus.displayName)"), systemImage: "circle.dashed.inset.fill")
            }
            
            Divider()
            
            if manager.systemStatus == .running {
                Button {
                    Task { @MainActor in
                        await manager.stopSystem() }
                } label: {
                    Label(String(localized: "menu.stop_system"), systemImage: "stop.circle")
                }
                .disabled(manager.isLoading)
            } else {
                Button {
                    Task { @MainActor in
                        await manager.startSystem() }
                } label: {
                    Label(String(localized: "menu.start_system"), systemImage: "play.circle")
                }
                .disabled(manager.isLoading)
            }
            
            Divider()
            
            if manager.systemStatus == .running {
                if manager.containers.isEmpty {
                    Text(String(localized: "menu.no_containers"))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                } else {
                    Text(String(localized: "menu.containers_count \(manager.containers.count)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                    
                    ForEach(manager.containers) { container in
                        ContainerMenuItem(container: container)
                    }
                }
                
                if manager.machines.isEmpty {
                    Text(String(localized: "menu.no_machines"))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                } else {
                    Divider()
                    
                    Text(String(localized: "menu.machines_count \(manager.machines.count)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                    
                    ForEach(manager.machines) { machine in
                        MachineMenuItem(machine: machine)
                    }
                }
                
                Divider()
            }
            
            Button {
                Task { @MainActor in
                    await manager.checkSystemStatus() }
            } label: {
                Label(String(localized: "menu.refresh"), systemImage: "arrow.clockwise")
            }
            .disabled(manager.isLoading)
            
            Button {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label(String(localized: "menu.container_management"), systemImage: "square.grid.2x2")
            }
            .keyboardShortcut(",")
            
            Divider()
            
            Button(String(localized: "menu.quit")) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

struct ContainerMenuItem: View {
    @Environment(ContainerManager.self) private var manager
    let container: ContainerInfo
    
    var body: some View {
        Menu {
            Text(String(localized: "container.image \(container.image)"))
            Text(String(localized: "container.hostname \(container.hostname)"))
            Text(String(localized: "container.cpu \(container.totalCpus)"))
            Text(String(localized: "container.memory \(container.memoryFormatted)"))
            Text(String(localized: "container.platform \(container.platform)"))
            
            Divider()
            
            if container.status == .running {
                Button(String(localized: "container.stop")) {
                    Task { @MainActor in
                        await manager.stopContainer(container) }
                }
            } else {
                Button(String(localized: "container.start")) {
                    Task { @MainActor in
                        await manager.startContainer(container) }
                }
            }
        } label: {
            HStack {
                Image(systemName: container.status == .running ? "cube.fill" : "cube")
                    .font(.caption)
                Text(container.name)
                Spacer()
                Text(container.statusText)
                    .font(.caption)
            }
        }
    }
}

struct MachineMenuItem: View {
    @Environment(ContainerManager.self) private var manager
    let machine: MachineInfo
    
    var body: some View {
        Menu {
            Text(String(localized: "machine.cpu \(machine.cpus)"))
            Text(String(localized: "machine.memory \(machine.memoryFormatted)"))
            Text(String(localized: "machine.disk \(machine.diskSizeFormatted)"))
            Text(String(localized: "machine.created \(machine.createdDateFormatted)"))
            if machine.isDefault {
                Text(String(localized: "machine.default"))
            }
            if machine.status == .running {
                Button(String(localized: "machine.stop")) {
                    Task { @MainActor in
                        await manager.stopMachine(machine) }
                }
            } else {
                Button(String(localized: "machine.start")) {
                    Task { @MainActor in
                        await manager.startMachine(machine) }
                }
            }
        } label: {
            HStack {
                Image(systemName: machine.status == .running ? "desktopcomputer" : "server.rack")
                    .font(.caption)
                Text(machine.name)
                Spacer()
                Text(machine.statusText)
                    .font(.caption)
            }
        }
    }
}
