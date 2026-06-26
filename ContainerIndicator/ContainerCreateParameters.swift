import Foundation

struct ContainerCreateParameters {
    var image: String = ""
    var arguments: [String] = []
    
    // MARK: Process Options
    var environmentVariables: [String] = []
    var envFiles: [String] = []
    var gid: String = ""
    var interactive: Bool = false
    var tty: Bool = false
    var user: String = ""
    var uid: String = ""
    var workdir: String = ""
    var ulimits: [String] = []
    
    // MARK: Resource Options
    var cpus: String = ""
    var memory: String = ""
    
    // MARK: Management Options
    var arch: String = ""
    var capAdd: [String] = []
    var capDrop: [String] = []
    var cidfile: String = ""
    var detach: Bool = false
    var dns: [String] = []
    var dnsDomain: String = ""
    var dnsOptions: [String] = []
    var dnsSearch: [String] = []
    var entrypoint: String = ""
    var useInit: Bool = false
    var initImage: String = ""
    var kernel: String = ""
    var labels: [String] = []
    var mounts: [String] = []
    var name: String = ""
    var network: String = ""
    var noDns: Bool = false
    var os: String = ""
    var publish: [String] = []
    var platform: String = ""
    var publishSockets: [String] = []
    var readOnly: Bool = false
    var remove: Bool = false
    var rosetta: Bool = false
    var runtime: String = ""
    var ssh: Bool = false
    var shmSize: String = ""
    var tmpfs: [String] = []
    var virtualization: Bool = false
    var volumes: [String] = []
}

extension ContainerCreateParameters {
    func buildArguments() -> [String] {
        var args = ["create"]
        
        // Process Options
        for env in environmentVariables where !env.isEmpty {
            args.append("--env")
            args.append(env)
        }
        for file in envFiles where !file.isEmpty {
            args.append("--env-file")
            args.append(file)
        }
        if !gid.isEmpty {
            args.append("--gid")
            args.append(gid)
        }
        if interactive {
            args.append("--interactive")
        }
        if tty {
            args.append("--tty")
        }
        if !user.isEmpty {
            args.append("--user")
            args.append(user)
        }
        if !uid.isEmpty {
            args.append("--uid")
            args.append(uid)
        }
        if !workdir.isEmpty {
            args.append("--workdir")
            args.append(workdir)
        }
        for limit in ulimits where !limit.isEmpty {
            args.append("--ulimit")
            args.append(limit)
        }
        
        // Resource Options
        if !cpus.isEmpty {
            args.append("--cpus")
            args.append(cpus)
        }
        if !memory.isEmpty {
            args.append("--memory")
            args.append(memory)
        }
        
        // Management Options
        if !arch.isEmpty {
            args.append("--arch")
            args.append(arch)
        }
        for cap in capAdd where !cap.isEmpty {
            args.append("--cap-add")
            args.append(cap)
        }
        for cap in capDrop where !cap.isEmpty {
            args.append("--cap-drop")
            args.append(cap)
        }
        if !cidfile.isEmpty {
            args.append("--cidfile")
            args.append(cidfile)
        }
        if detach {
            args.append("--detach")
        }
        for server in dns where !server.isEmpty {
            args.append("--dns")
            args.append(server)
        }
        if !dnsDomain.isEmpty {
            args.append("--dns-domain")
            args.append(dnsDomain)
        }
        for option in dnsOptions where !option.isEmpty {
            args.append("--dns-option")
            args.append(option)
        }
        for domain in dnsSearch where !domain.isEmpty {
            args.append("--dns-search")
            args.append(domain)
        }
        if !entrypoint.isEmpty {
            args.append("--entrypoint")
            args.append(entrypoint)
        }
        if useInit {
            args.append("--init")
        }
        if !initImage.isEmpty {
            args.append("--init-image")
            args.append(initImage)
        }
        if !kernel.isEmpty {
            args.append("--kernel")
            args.append(kernel)
        }
        for label in labels where !label.isEmpty {
            args.append("--label")
            args.append(label)
        }
        for mount in mounts where !mount.isEmpty {
            args.append("--mount")
            args.append(mount)
        }
        if !name.isEmpty {
            args.append("--name")
            args.append(name)
        }
        if !network.isEmpty {
            args.append("--network")
            args.append(network)
        }
        if noDns {
            args.append("--no-dns")
        }
        if !os.isEmpty {
            args.append("--os")
            args.append(os)
        }
        for spec in publish where !spec.isEmpty {
            args.append("--publish")
            args.append(spec)
        }
        if !platform.isEmpty {
            args.append("--platform")
            args.append(platform)
        }
        for socket in publishSockets where !socket.isEmpty {
            args.append("--publish-socket")
            args.append(socket)
        }
        if readOnly {
            args.append("--read-only")
        }
        if remove {
            args.append("--remove")
        }
        if rosetta {
            args.append("--rosetta")
        }
        if !runtime.isEmpty {
            args.append("--runtime")
            args.append(runtime)
        }
        if ssh {
            args.append("--ssh")
        }
        if !shmSize.isEmpty {
            args.append("--shm-size")
            args.append(shmSize)
        }
        for tmp in tmpfs where !tmp.isEmpty {
            args.append("--tmpfs")
            args.append(tmp)
        }
        if virtualization {
            args.append("--virtualization")
        }
        for volume in volumes where !volume.isEmpty {
            args.append("--volume")
            args.append(volume)
        }
        
        // Required image and positional arguments
        args.append(image)
        args.append(contentsOf: arguments)
        
        return args
    }
}
