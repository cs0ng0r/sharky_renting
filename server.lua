ESX.RegisterServerCallback('mta_renting:canAfford', function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(xPlayer.getMoney() >= amount)
end)


RegisterNetEvent('mta_renting:pay')
AddEventHandler('mta_renting:pay', function(price, caution)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeMoney(price + caution)

    -- Save rental data to the player
    xPlayer.set('rentedVehicle', {
        price = price,
        caution = caution,
        netId = nil, 
    })
end)

RegisterNetEvent('mta_renting:returnCaution')
AddEventHandler('mta_renting:returnCaution', function(caution)
    local xPlayer = ESX.GetPlayerFromId(source)
    local rentedVehicle = xPlayer.get('rentedVehicle')


    if rentedVehicle and rentedVehicle.caution == caution then
        xPlayer.addMoney(caution)
        xPlayer.set('rentedVehicle', nil)  
    else
        print(('Megprobalt leadni egy kocsit amit nem ő bérelt %s'):format(xPlayer.identifier))
    end
end)

-- Handle vehicle timeout
RegisterNetEvent('mta_renting:vehicleTimeout')
AddEventHandler('mta_renting:vehicleTimeout', function(netId)
    print(('Vehicle with Net ID %s has timed out.'):format(netId))
end)

-- Handle vehicle destruction
RegisterNetEvent('mta_renting:vehicleDestroyed')
AddEventHandler('mta_renting:vehicleDestroyed', function(netId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local rentedVehicle = xPlayer.get('rentedVehicle')
    if rentedVehicle and rentedVehicle.netId == netId then
        -- Optional: Add logic here if you want to log or handle vehicle destruction
        print(('%s törölt egy kocsit amit ő bérelt: %s'):format(netId, xPlayer.identifier))
        xPlayer.set('rentedVehicle', nil)  -- Clear rental data
    else
        print(('Megprobalt törölni egy kocsit amit nem ő bérelt %s'):format(xPlayer.identifier))
    end
end)
