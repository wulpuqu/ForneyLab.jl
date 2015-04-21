export generateSchedule!, generateSchedule

function generateSchedule(outbound_interface::Interface, scheme::InferenceScheme=currentScheme(); args...)
    # Generate a schedule that can be executed to calculate the outbound message on outbound_interface.
    #
    # IMPORTANT: the resulting schedule depends on the current messages stored in the factor graph.
    # The same graph with different messages being present can (and probably will) result in a different schedule.
    #
    # When a lot of iterations of the same message passing schedule are required, it can be very beneficial
    # to generate the schedule just once using this function, and then execute the same schedule over and over.
    # This prevents having to generate the same schedule in every call to calculateMessage!().

    return convert(Schedule, generateScheduleByDFS(outbound_interface, Array(Interface, 0), Array(Interface, 0), scheme; args...))
end
function generateSchedule!(outbound_interface::Interface, scheme::InferenceScheme=currentScheme(); args...)
    schedule = generateSchedule(outbound_interface, scheme; args...)
    return subgraph(scheme, outbound_interface.edge).internal_schedule = schedule
end

function generateSchedule(partial_schedule::Schedule, scheme::InferenceScheme=currentScheme(); args...)
    # Generate a complete schedule based on partial_schedule.
    # A partial schedule only defines the order of a subset of all required messages.
    # This function will find a valid complete schedule that satisfies the partial schedule.
    #
    # IMPORTANT: the resulting schedule depends on the current messages stored in the factor graph.

    # Verify that all entries in partial_schedule belong to the same subgraph
    (length(partial_schedule) > 0) || error("Partial schedule should contain at least one entry")

    for schedule_entry in partial_schedule
        is(subgraph(scheme, schedule_entry.interface.edge), subgraph(scheme, partial_schedule[1].interface.edge)) || error("Not all interfaces in your partial schedule belong to the same subgraph")
    end

    interface_list = Array(Interface, 0)
    for schedule_entry in partial_schedule
        interface_list = generateScheduleByDFS(schedule_entry.interface, interface_list, Array(Interface, 0), scheme; args...)
    end

    return convert(Schedule, interface_list)
end
generateSchedule(partial_list::Array{Interface, 1}, scheme::InferenceScheme=currentScheme(); args...) = generateSchedule(convert(Schedule, partial_list), scheme; args...)
function generateSchedule!(partial_schedule::Schedule, scheme::InferenceScheme=currentScheme(); args...)
    schedule = generateSchedule(partial_schedule, scheme; args...)
    return subgraph(scheme, partial_schedule[1].edge).internal_schedule = schedule
end
generateSchedule!(partial_list::Array{Interface, 1}, scheme::InferenceScheme=currentScheme(); args...) = generateSchedule!(convert(Schedule, partial_list), scheme; args...)

function generateSchedule!(sg::Subgraph, scheme::InferenceScheme=currentScheme())
    # Generate an internal and external schedule for the subgraph

    interface_list_for_univariate = Array(Interface, 0)
    internal_interface_list = Array(Interface, 0)
    sg.internal_schedule = Array(ScheduleEntry, 0)
    # The internal schedule makes sure that incoming internal messages over internal edges connected to nodes (g) are present
    for g_node in nodesConnectedToExternalEdges(sg) # All nodes that are connected to at least one external edge
        outbound_interfaces = Array(Interface, 0) # Array that holds required outbound for the case of one internal edge connected to g_node
        for interface in g_node.interfaces
            if interface.edge in sg.internal_edges # edge carries incoming internal message
                # Store outbound interfaces for check later on
                if !(interface in internal_interface_list) && !(interface in interface_list_for_univariate)
                    push!(outbound_interfaces, interface) # If we were to add the outbound to the schedule (for the case of univariate q), this is the one
                end

                # Extend internal_schedule to calculate the inbound message on interface
                try
                    internal_interface_list = generateScheduleByDFS(interface.partner, internal_interface_list, Array(Interface, 0), scheme, stay_in_subgraph=true)
                catch
                    error("Cannot generate internal schedule for possibly loopy subgraph with internal edge $(interface.edge).")
                end
            end
        end

        # For the case that g_node is connected to one internal edge,
        # the calculation reduces to the naive vmp update which requires the outbound (Dauwels, 2007)
        if length(outbound_interfaces) == 1
            push!(interface_list_for_univariate, outbound_interfaces[1])
        end
    end

    # Make sure that messages are propagated to the timewraps
    interface_list_for_time_wraps = Array(Interface, 0)
    for (from_node, to_node) in scheme.time_wraps
        if subgraph(scheme, from_node.out.edge) == sg # Timewrap is the responsibility of this subgraph
            interface_list_for_time_wraps = [interface_list_for_time_wraps, generateScheduleByDFS(from_node.out.partner, Array(Interface, 0), Array(Interface, 0), scheme, stay_in_subgraph=true)]
        end
    end

    # Make sure that messages are propagated to the write buffers
    interface_list_for_write_buffers = Array(Interface, 0)
    for entry in keys(scheme.write_buffers)
        if typeof(entry) == Interface
            interface_list_for_write_buffers = [interface_list_for_write_buffers, generateScheduleByDFS(entry, Array(Interface, 0), Array(Interface, 0), scheme, stay_in_subgraph=true)]
        elseif typeof(entry) == Edge
            interface_list_for_write_buffers = [interface_list_for_write_buffers, generateScheduleByDFS(entry.head, Array(Interface, 0), Array(Interface, 0), scheme, stay_in_subgraph=true)]
            interface_list_for_write_buffers = [interface_list_for_write_buffers, generateScheduleByDFS(entry.tail, Array(Interface, 0), Array(Interface, 0), scheme, stay_in_subgraph=true)]
        end
    end

    # Schedule for univariate comes after internal schedule, because it can depend on inbounds
    sg.internal_schedule = convert(Schedule, unique([internal_interface_list, interface_list_for_univariate, interface_list_for_time_wraps, interface_list_for_write_buffers]))

    return sg
end

function generateSchedule!(scheme::InferenceScheme=currentScheme())
    for subgraph in scheme.factorization
        generateSchedule!(subgraph, scheme)
    end
    return scheme
end

function generateScheduleByDFS(outbound_interface::Interface, backtrace::Array{Interface, 1}=Array(Interface, 0), call_list::Array{Interface, 1}=Array(Interface, 0), scheme::InferenceScheme=currentScheme(); stay_in_subgraph=false)
    # This is a private function that performs a search through the factor graph to generate a schedule.
    #
    # IMPORTANT: the resulting schedule depends on the current messages stored in the factor graph.
    #
    # This is a recursive implementation of DFS. The recursive calls are stored in call_list.
    # backtrace will hold the backtrace.

    node = outbound_interface.node

    # Apply stopping condition for recursion. When the same interface is called twice, this is indicative of an unbroken loop.
    if outbound_interface in call_list
        # Notify the user to break the loop with an initial message
        error("Loop detected around $(outbound_interface) Consider setting an initial message somewhere in this loop.")
    elseif outbound_interface in backtrace
        # This outbound_interface is already in the schedule
        return backtrace
    else # Stopping condition not satisfied
        push!(call_list, outbound_interface)
    end

    # Check all inbound messages on the other interfaces of the node
    outbound_interface_id = 0
    for interface_id = 1:length(node.interfaces)
        interface = node.interfaces[interface_id]
        if is(interface, outbound_interface)
            outbound_interface_id = interface_id
        end
        if ((outbound_interface_id==interface_id) || # In the future this should be replaced by a decent dependency checking system
            (stay_in_subgraph && subgraph(scheme, outbound_interface.edge) != subgraph(scheme, interface.edge))) # Internal subgraph schedule generation and edges are on different subgraphs
            continue
        end
        (interface.partner != nothing) || error("Disconnected interface should be connected: interface #$(interface_id) of $(typeof(node)) $(node.name)")

        if interface.partner.message == nothing # Required message missing.
            if !(interface.partner in backtrace) # Don't recalculate stuff that's already in the schedule.
                # Recursive call
                generateScheduleByDFS(interface.partner, backtrace, call_list, scheme, stay_in_subgraph=stay_in_subgraph)
            end
        end
    end

    # Update call_list and backtrace
    pop!(call_list)

    return push!(backtrace, outbound_interface)
end