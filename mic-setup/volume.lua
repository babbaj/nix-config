-- something is setting the volume of some of my programs to random values and i dont know what but this will fix it for the programs I care about

node_om = ObjectManager {
    Interest {
        type = 'node',
        Constraint { 'node.name', 'in-list', 'pw-cat', 'Looking Glass' }
    }
}

defaultVolumes = {
    ['pw-cat'] = 1.0,
    ['Looking Glass'] = 0.5 -- actually about 80%
}

function parseParam(param, id)
    local parsed = param:parse()
    if parsed.pod_type == "Object" and parsed.object_id == id then
      return parsed.properties
    else
      return nil
    end
end


node_om:connect("object-added", function (om, node)
    local name = node.properties['node.name']
    for x in node:iterate_params("Props") do
        local params = parseParam(x, "Props")
        local numChannels = #params["channelVolumes"]
        local volumes = {}
        while #volumes < numChannels do
            table.insert(volumes, defaultVolumes[name])
        end
        print(name)
        print("meow")

        table.insert(volumes, 1, "Spa:Float")
        volumes = Pod.Array(volumes)
        local newProps = {
            "Spa:Pod:Object:Param:Props", "Props",
            channelVolumes = volumes
        }
        node:set_param("Props", Pod.Object(newProps))
    end
end)

node_om:activate()
