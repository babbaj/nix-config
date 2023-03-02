#!/usr/bin/env wpexec

-- this is mad gay but the behavior of wireplumber is even more mad gay

proxy_om = ObjectManager {
    Interest {
        type = 'node',
        Constraint { 'node.name', '=', 'EasyEffectsProxySink'}
    }
}

capture_port_fl_om = ObjectManager {
    Interest {
        type = "port",
        Constraint { "port.alias", "=", "Easy Effects Source:capture_FL" }
    }
}
capture_port_fr_om = ObjectManager {
    Interest {
        type = "port",
        Constraint { "port.alias", "=", "Easy Effects Source:capture_FR" }
    }
}

playback_port_fl_om = ObjectManager {
    Interest {
        type = "port",
        Constraint { "port.alias", "=", "EasyEffects Proxy:playback_FL" }
    }
}
playback_port_fr_om = ObjectManager {
    Interest {
        type = "port",
        Constraint { "port.alias", "=", "EasyEffects Proxy:playback_FR" }
    }
}

function make_link(playback_om, port)
    local proxy_port = playback_om:lookup()
    if proxy_port == nil then return end
    local proxy_id = proxy_port.properties["object.id"]

    local new_link = Link("link-factory", {
        ["link.output.port"] = port.properties["object.id"], -- link from easyeffects source
        ["link.input.port"] = proxy_id, -- to the proxy sink
        ["object.linger"] = 1
    })
    new_link:activate(Features.ALL)
end

capture_port_fl_om:connect("object-added", function (om, port)
    make_link(playback_port_fl_om, port)
end)
capture_port_fr_om:connect("object-added", function (om, port)
    make_link(playback_port_fr_om, port)
end)


proxy_om:activate()
playback_port_fl_om:activate()
playback_port_fr_om:activate()
capture_port_fl_om:activate()
capture_port_fr_om:activate()
