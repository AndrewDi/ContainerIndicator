import SwiftUI

struct CreateContainerView: View {
    @Environment(ContainerManager.self) private var manager
    @Environment(\.dismiss) private var dismiss

    @State private var parameters = ContainerCreateParameters()
    @State private var newArgument = ""

    private var isValid: Bool {
        !trimmed(parameters.image).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "dialog.basic")) {
                    Picker(String(localized: "dialog.image"), selection: $parameters.image) {
                        Text(String(localized: "dialog.select_image")).tag("")
                        ForEach(manager.availableImages) { image in
                            Text(image.reference).tag(image.reference)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField(String(localized: "dialog.name"), text: $parameters.name)
                }

                Section(String(localized: "dialog.resources")) {
                    Picker(String(localized: "dialog.cpus"), selection: $parameters.cpus) {
                        Text(String(localized: "dialog.ulimited")).tag("")
                        ForEach(1...12, id: \.self) { cpu in
                            Text("\(cpu)").tag("\(cpu)")
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker(String(localized: "dialog.memory"), selection: $parameters.memory) {
                        Text(String(localized: "dialog.ulimited")).tag("")
                        Text("128 MB").tag("128m")
                        Text("256 MB").tag("256m")
                        Text("512 MB").tag("512m")
                        Text("1 GB").tag("1g")
                        Text("2 GB").tag("2g")
                        Text("4 GB").tag("4g")
                        Text("8 GB").tag("8g")
                        Text("16 GB").tag("16g")
                    }
                    .pickerStyle(.menu)
                }

                Section(String(localized: "dialog.environment")) {
                    EditableListView(items: $parameters.environmentVariables, placeholder: "KEY=value")
                }

                Section(String(localized: "dialog.ports")) {
                    EditableListView(
                        items: $parameters.publish,
                        placeholder: "[host-ip:]host-port:container-port[/protocol]"
                    )
                }

                Section(String(localized: "dialog.volumes")) {
                    EditableListView(items: $parameters.volumes, placeholder: "/host:/container")
                }

                Section(String(localized: "dialog.arguments")) {
                    argumentInput
                }

                DisclosureGroup(String(localized: "dialog.advanced")) {
                    advancedSection
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "dialog.create_container"))
            .task {
                await manager.refreshAvailableImages()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "dialog.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "dialog.create")) {
                        Task {
                            await manager.createContainer(parameters)
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(minWidth: 520, minHeight: 640)
    }

    private var argumentInput: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("argument", text: $newArgument)
                Button {
                    let value = trimmed(newArgument)
                    guard !value.isEmpty else { return }
                    parameters.arguments.append(value)
                    newArgument = ""
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.borderless)
                .disabled(trimmed(newArgument).isEmpty)
            }

            ForEach(Array(parameters.arguments.enumerated()), id: \.offset) { index, arg in
                HStack {
                    Text(arg)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        parameters.arguments.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    @ViewBuilder
    private var advancedSection: some View {
        Section(String(localized: "dialog.process_options")) {
            EditableListView(items: $parameters.envFiles, placeholder: "/path/to/env-file")
            TextField("GID", text: $parameters.gid)
            Toggle("Interactive", isOn: $parameters.interactive)
            Toggle("TTY", isOn: $parameters.tty)
            TextField("User", text: $parameters.user)
            TextField("UID", text: $parameters.uid)
            TextField("Working Directory", text: $parameters.workdir)
            EditableListView(items: $parameters.ulimits, placeholder: "<type>=<soft>[:<hard>]")
        }

        Section(String(localized: "dialog.management_options")) {
            TextField("Architecture", text: $parameters.arch)
            EditableListView(items: $parameters.capAdd, placeholder: "CAP_NET_RAW")
            EditableListView(items: $parameters.capDrop, placeholder: "CAP_NET_RAW")
            TextField("CID File", text: $parameters.cidfile)
            Toggle("Detach", isOn: $parameters.detach)
            EditableListView(items: $parameters.dns, placeholder: "DNS IP")
            TextField("DNS Domain", text: $parameters.dnsDomain)
            EditableListView(items: $parameters.dnsOptions, placeholder: "DNS option")
            EditableListView(items: $parameters.dnsSearch, placeholder: "search domain")
            TextField("Entrypoint", text: $parameters.entrypoint)
            Toggle("Use Init", isOn: $parameters.useInit)
            TextField("Init Image", text: $parameters.initImage)
            TextField("Kernel", text: $parameters.kernel)
            EditableListView(items: $parameters.labels, placeholder: "key=value")
            EditableListView(items: $parameters.mounts, placeholder: "type=<>,source=<>,target=<>,readonly")
            TextField("Network", text: $parameters.network)
            Toggle("No DNS", isOn: $parameters.noDns)
            TextField("OS", text: $parameters.os)
            TextField("Platform", text: $parameters.platform)
            EditableListView(items: $parameters.publishSockets, placeholder: "host_path:container_path")
            Toggle("Read Only", isOn: $parameters.readOnly)
            Toggle("Remove on Stop", isOn: $parameters.remove)
            Toggle("Rosetta", isOn: $parameters.rosetta)
            TextField("Runtime", text: $parameters.runtime)
            Toggle("SSH Forward", isOn: $parameters.ssh)
            TextField("SHM Size", text: $parameters.shmSize)
            EditableListView(items: $parameters.tmpfs, placeholder: "/path")
            Toggle("Virtualization", isOn: $parameters.virtualization)
        }
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}

struct EditableListView: View {
    @Binding var items: [String]
    var placeholder: String = ""

    @State private var newValue = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack {
                    Text(item)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        items.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }

            HStack {
                TextField(placeholder, text: $newValue)
                Button {
                    let value = newValue.trimmingCharacters(in: CharacterSet.whitespaces)
                    guard !value.isEmpty else { return }
                    items.append(value)
                    newValue = ""
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.borderless)
                .disabled(newValue.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty)
            }
        }
    }
}
