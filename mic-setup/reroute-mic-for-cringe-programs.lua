#!/usr/bin/env wpexec

steam_om = ObjectManager {
    Interest {
        type = 'node',
        Constraint { 'node.name', 'in-list', 'steam'}
    }
}

easyeffects_om = ObjectManager {
    Interest {
        type = 'node',
        Constraint { 'node.name', '=', 'easyeffects_source'}
    }
}

capture_port_om = ObjectManager {
    Interest {
        type = "port",
        Constraint { "port.direction", "=", "out" }
    }
}

link_om = ObjectManager {
    Interest {
        type = "link"
    }
}

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

 -- avoid gc
links = {}

link_om:connect("object-added", function (om, link)
    local parent_node = link.properties["link.input.node"]
    local steam = steam_om:lookup{ Constraint {"object.id", "=", parent_node} }
    if steam == nil then return end
    local easyeffects = easyeffects_om:lookup()
    if easyeffects == nil then return end
    local easyeffects_id = easyeffects.properties["object.id"]
    -- look up the port that we are already linked to (the alsa device), and get the channel ("FL"/"FR")
    local linked_to_port = capture_port_om:lookup{ Constraint{"object.id", "=", link.properties["link.output.port"]}}
    local channel = linked_to_port.properties["audio.channel"]
    local easyeffects_port = capture_port_om:lookup{ Constraint{"node.id", "=", easyeffects_id}, Constraint{"audio.channel", "=", channel}}
    if easyeffects_port.properties["object.id"] == linked_to_port.properties["object.id"] then
        return
    end

    link:request_destroy()
    local input_port = link.properties["link.input.port"]
    local new_link = Link("link-factory", {
        ["link.output.port"] = easyeffects_port.properties["object.id"], -- link to easyeffects output
        ["link.input.port"] = input_port, -- keep the same input
    })
    new_link:activate(Features.ALL)
    table.insert(links, new_link)
end)

link_om:connect("object-removed", function (om, link)
    local index
    for i, val in ipairs(links) do
        if val == link then
            index = i
            break
        end
    end
    if index then
        table.remove(links, index)
    end
end)


easyeffects_om:activate()
steam_om:activate()
capture_port_om:activate()
link_om:activate()
