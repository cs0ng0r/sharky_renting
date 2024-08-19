-- Check if the player can afford the rental
ESX.RegisterServerCallback('mta_renting:canAfford', function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(xPlayer.getMoney() >= amount)
end)

-- Deduct the money from the player and store rental data
RegisterNetEvent('mta_renting:pay')
AddEventHandler('mta_renting:pay', function(price, caution)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeMoney(price + caution)

    -- Save rental data to the player
    xPlayer.set('rentedVehicle', {
        price = price,
        caution = caution,
        netId = nil,  -- This will be set by the client later
    })
end)

-- Handle vehicle return and caution refund
RegisterNetEvent('mta_renting:returnCaution')
AddEventHandler('mta_renting:returnCaution', function(caution)
    local xPlayer = ESX.GetPlayerFromId(source)
    local rentedVehicle = xPlayer.get('rentedVehicle')

    -- Ensure the player is returning a vehicle they rented
    if rentedVehicle and rentedVehicle.caution == caution then
        xPlayer.addMoney(caution)
        xPlayer.set('rentedVehicle', nil)  -- Clear rental data
    else
        -- Potential cheating attempt, log it for further review
        print(('Player %s attempted to return a vehicle they didn\'t rent.'):format(xPlayer.identifier))
    end
end)

-- Handle vehicle timeout
RegisterNetEvent('mta_renting:vehicleTimeout')
AddEventHandler('mta_renting:vehicleTimeout', function(netId)
    -- Optional: Add logic here if you want to log or handle vehicle timeouts
    print(('Vehicle with Net ID %s has timed out.'):format(netId))
end)

-- Handle vehicle destruction
RegisterNetEvent('mta_renting:vehicleDestroyed')
AddEventHandler('mta_renting:vehicleDestroyed', function(netId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local rentedVehicle = xPlayer.get('rentedVehicle')

    -- Ensure the vehicle being destroyed is the one the player rented
    if rentedVehicle and rentedVehicle.netId == netId then
        -- Optional: Add logic here if you want to log or handle vehicle destruction
        print(('Vehicle with Net ID %s rented by Player %s was destroyed.'):format(netId, xPlayer.identifier))
        xPlayer.set('rentedVehicle', nil)  -- Clear rental data
    else
        -- Potential cheating attempt, log it for further review
        print(('Player %s attempted to destroy a vehicle they didn\'t rent.'):format(xPlayer.identifier))
    end
end)
