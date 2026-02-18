N = "3" # Tu número de clase
iniciales = "idh"

# CORRECCIÓN: Se usa exist? en lugar de exists?
if File.exist?("./secrets.txt")
  File.foreach("./secrets.txt") do |line|
    key, value = line.strip.split('=') 
    ENV[key] = value if key && value
  end
end

Vagrant.configure("2") do |config|

  # Definición del equipo gw
  config.vm.define "gw" do |gw|
    gw.vm.box = "bento/ubuntu-24.04"
    gw.vm.hostname = "gw-#{iniciales}"
    gw.vm.network "private_network", ip: "203.0.113.254", netmask: "255.255.255.0", virtualbox__intnet: "red_wan"
    gw.vm.network "private_network", ip: "172.1.#{N}.1", netmask: "255.255.255.0", virtualbox__intnet: "red_dmz" 
    gw.vm.network "private_network", ip: "172.2.#{N}.1", netmask: "255.255.255.0", virtualbox__intnet: "red_lan"
    gw.vm.provision "shell", path: "gw/provision.sh"   
    gw.vm.provider "virtualbox" do |vb|
        vb.name = "gw"
        vb.gui = false
        vb.memory = "768"
        vb.cpus = 1
        vb.linked_clone = true
        vb.customize ["modifyvm", :id, "--groups", "/sad"]
    end
  end        
  
  # IDP en la LAN
  config.vm.define "idp" do |idp|
    idp.vm.box = "bento/ubuntu-24.04"
    idp.vm.hostname = "idp-#{iniciales}"
    idp.vm.network "private_network", ip: "172.2.#{N}.2", netmask: "255.255.255.0", virtualbox__intnet: "red_lan"
    
    # Provisión con variables de entorno (limpiado el duplicado)
    idp.vm.provision "shell" do |s|
      s.path = "idp/provision.sh"
      s.env = { "LDAP_PASS" => ENV["LDAP_PASS"] }
    end     

    # Cambio de Gateway (añadido para que tenga salida por el GW)
    idp.vm.provision "shell", run: "always" do |s|
      s.inline = "ip route del default && ip route add default via 172.2.#{N}.1"
    end

    idp.vm.provider "virtualbox" do |vb|
        vb.name = "idp-lan"
        vb.gui = false
        vb.memory = "512"
        vb.cpus = 1
        vb.linked_clone = true
        vb.customize ["modifyvm", :id, "--groups", "/sad"]
    end
  end

  # Adminpc en la LAN
  config.vm.define "adminpc" do |adminpc|
    adminpc.vm.box = "generic/alpine319"
    adminpc.vm.hostname = "adminpc-#{iniciales}"
    adminpc.vm.network "private_network", ip: "172.2.#{N}.10", netmask: "255.255.255.0", virtualbox__intnet: "red_lan"
    adminpc.vm.provision "shell",
        path: "adminpc/provision.sh",
        env: {
          "EMP_USERNAME" => ENV["EMP_USERNAME"],
          "EMP_PASS" => ENV["EMP_PASS"]
        }
    adminpc.vm.provision "shell", run: "always", inline: "ip route del default && ip route add default via 172.2.#{N}.1"   
    adminpc.vm.provider "virtualbox" do |vb|
        vb.name = "adminpc-lan"
        vb.memory = "128"
    end
  end

  # Empleado en la LAN
  config.vm.define "empleado" do |empleado|
    empleado.vm.box = "generic/alpine319"
    empleado.vm.hostname = "empleado-#{iniciales}"
    empleado.vm.network "private_network", ip: "172.2.#{N}.100", netmask: "255.255.255.0", virtualbox__intnet: "red_lan"
    empleado.vm.provision "shell", path: "empleado/provision.sh"
    empleado.vm.provision "shell", run: "always", inline: "ip route del default && ip route add default via 172.2.#{N}.1"   
    empleado.vm.provider "virtualbox" do |vb|
        vb.name = "empleado-lan"
        vb.memory = "128"
    end
  end

  # Proxy en DMZ
  config.vm.define "proxy" do |proxy|
    proxy.vm.box = "bento/ubuntu-24.04"
    proxy.vm.hostname = "proxy-#{iniciales}"
    proxy.vm.network "private_network", ip: "172.1.#{N}.2", netmask: "255.255.255.0", virtualbox__intnet: "red_dmz" 
    proxy.vm.provision "shell", path: "proxy/provision.sh"
    proxy.vm.provision "shell", run: "always", inline: "ip route del default && ip route add default via 172.1.#{N}.1"       
    proxy.vm.provider "virtualbox" do |vb|
        vb.name = "proxy-dmz"
        vb.memory = "1024"
    end
  end

  # WWW en DMZ
  config.vm.define "www" do |www|
    www.vm.box = "generic/alpine319"
    www.vm.hostname = "www-#{iniciales}"
    www.vm.network "private_network", ip: "172.1.#{N}.3", netmask: "255.255.255.0", virtualbox__intnet: "red_dmz" 
    www.vm.provision "shell", path: "www/provision.sh"
    www.vm.provision "shell", run: "always", inline: "ip route del default && ip route add default via 172.1.#{N}.1"     
    www.vm.provider "virtualbox" do |vb|
        vb.name = "www-dmz"
        vb.memory = "512"
    end
  end
end