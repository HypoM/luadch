--[[

        hub_inf_manager by blastbeat

        - this script kills users with forbidden inf flags
        - do not change anything here when you dont know what you are doing
    
        v0.04: by pulsar
            - commented "I4" in flags_on_inf table to prevent check
        
        v0.03: by blastbeat
          - updated script api

]]--

local scriptname = "hub_inf_manager"
local scriptversion = "0.04"
local scriptlang = cfg.get "language"

local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local msg_invalid = hub.escapeto( lang.msg_invalid or "invalid named parameter in inf: " )

--// forbidden named parameters in inf //--

local forbidden = {

    flags = {
        
        "HI",
        "CT",
        "OP",
        "RG",
        "HU",
        "BO",

    },
    flags_on_inf = {

        "PD",
        "ID",
        --"I4",

    },

}

local check = function( cmd, flags )
    for i, name in ipairs( flags ) do    -- check if user sends forbidden parameters...
        if cmd:getnp( name ) then
            return nil, ( name or "" )
        end
    end
    return true
end

hub.setlistener( "onConnect", { },
    function( user )
        local cmd = user:inf( )
        local valid, offending_flag = check( cmd, forbidden.flags )
        if not valid then
            user:kill( "ISTA 240 " .. msg_invalid .. offending_flag .. "\n" )
            return PROCESSED
        end
        return nil
    end
)

hub.setlistener( "onInf", { },
    function( user, cmd )
        local valid, offending_flag = check( cmd, forbidden.flags )
        if not valid then
            user:kill( "ISTA 240 " .. msg_invalid .. offending_flag .. "\n" )
            return PROCESSED
        end
        valid, offending_flag = check( cmd, forbidden.flags_on_inf )
        if not valid then
            user:kill( "ISTA 240 " .. msg_invalid .. offending_flag .. "\n" )
            return PROCESSED
        end
        local discard
        local user_inf = user:inf( )
        for name, value in cmd:getallnp( ) do
            if name == "NI" then
                if cfg.get "nick_change" then    -- nick change allowed?
                    local bol, err = user:updatenick( value, true )
                    if err then
                        cmd:deletenp "NI"
                        user:reply( err, hub.getbot( ) )
                    end
                else
                    cmd:deletenp "NI"    -- delete new nick from inf
                    --discard = true    -- no parameter left in inf -> discard message
                end
            else
                user_inf:setnp( name, value )    -- change user inf
            end
        end
        if discard then
            return PROCESSED
        else
            return nil
        end
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )