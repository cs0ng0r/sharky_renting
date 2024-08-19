local currentRentPoint = nil
local rentedVehicles = {}

function SendNotification(message)
    ESX.ShowNotification(message)
end

-- Function to open the rental menu
function OpenRentalMenu(rentPoint)
    currentRentPoint = rentPoint

    local vehicles = settings["rents"][rentPoint]["vehicles"]
    local vehicleData = {}

    for _, vehicle in pairs(vehicles) do
        vehicleData[#vehicleData + 1] = {
            name = vehicle.name,
            model = vehicle.model,
            price = vehicle.price,
            caution = vehicle.caution
        }
    end

    SendNUIMessage({
        action = 'openMenu',
        vehicles = vehicleData
    })
    SetNuiFocus(true, true)
end

-- Register NUI callback for closing the menu
RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeMenu' })
    cb('ok')
end)

-- NUI callback to handle renting a vehicle
RegisterNUICallback('rentVehicle', function(data, cb)
    if not currentRentPoint then
        SendNotification("Error: Nem található bérlési pont.")
        return cb('ok')
    end

    local fullPrice = data.price + data.caution

    ESX.TriggerServerCallback('mta_renting:canAfford', function(canAfford)
        if canAfford then
            local spawnCoords = settings["rents"][currentRentPoint]["coords"]["spawn"]
            SpawnRentalVehicle(data.model, spawnCoords, data.price, data.caution)
        else
            SendNotification(settings["locales"]["not_enough_money"])
        end
    end, fullPrice)

    cb('ok')
end)

function MonitorRentalVehicle(vehicle, netId)
    CreateThread(function()
        local timer = 600000 -- 10 minutes

        while timer > 0 do
            Wait(1000)
            timer = timer - 1000
        end

        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
            TriggerServerEvent('mta_renting:vehicleTimeout', netId)
        end
    end)
end

-- Function to spawn the rental vehicle
function SpawnRentalVehicle(model, spawnCoords, price, caution)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)

    while not HasModelLoaded(modelHash) do
        Wait(10)
    end

    local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, true)

    if not DoesEntityExist(vehicle) then
        SendNotification("Failed to spawn vehicle.")
        return
    end

    SetVehicleNumberPlateText(vehicle, "BERLES")

    local playerPed = PlayerPedId()
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    if netId == 0 then
        SendNotification("Failed to obtain Network ID for the vehicle.")
        DeleteEntity(vehicle)
        return
    end

    SetNetworkIdCanMigrate(netId, true)

    rentedVehicles[#rentedVehicles + 1] = { vehicle = vehicle, netId = netId, caution = caution }
    TriggerServerEvent('mta_renting:pay', price, caution)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeMenu' })

    MonitorRentalVehicle(vehicle, netId)
end


function ReturnRentalVehicle()
    for i, rentedVehicle in pairs(rentedVehicles) do
        if IsPedInVehicle(PlayerPedId(), rentedVehicle.vehicle, false) then
            local health = GetVehicleEngineHealth(rentedVehicle.vehicle)
            local message = health > 800 and "A Jármű leadva, a kauciót visszakaptad." or
                "Összetörted a kocsit, a kauciót nem kaptad vissza."

            if health > 800 then
                TriggerServerEvent('mta_renting:returnCaution', rentedVehicle.caution)
            end

            -- Use the stored Net ID to delete and clean up the vehicle
            if NetworkDoesNetworkIdExist(rentedVehicle.netId) then
                local vehicle = NetworkGetEntityFromNetworkId(rentedVehicle.netId)
                if DoesEntityExist(vehicle) then
                    DeleteEntity(vehicle)
                end
            end

            SendNotification(message)
            table.remove(rentedVehicles, i)
            break
        end
    end
end


local function HandleMarkers()
    while true do
        local sleep = 1000 -- Reduce checks when player is not nearby

        local playerCoords = GetEntityCoords(PlayerPedId())
        for key, rent in pairs(settings["rents"]) do
            local markerCoords = rent.coords["marker"]
            local returnCoords = rent.coords["return"]
            local distanceToMarker = #(playerCoords - markerCoords)
            local distanceToReturn = #(playerCoords - returnCoords)

            if distanceToMarker < 10.0 then
                sleep = 0
                DrawMarker(1, markerCoords.x, markerCoords.y, markerCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 255, false, false, 2, false, nil, nil, false)
                DrawMarker(36, markerCoords.x, markerCoords.y, markerCoords.z + 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 255, false, true, 2, false, nil, nil, false)

                if distanceToMarker < 2.0 then
                    ESX.ShowHelpNotification(settings["locales"]["rent_open"])
                    if IsControlJustPressed(1, 51) then
                        OpenRentalMenu(key)
                    end
                end
            end

            if distanceToReturn < 10.0 then
                sleep = 0
                DrawMarker(1, returnCoords.x, returnCoords.y, returnCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 255, false, false, 2, false, nil, nil, false)
                DrawMarker(24, returnCoords.x, returnCoords.y, returnCoords.z + 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, 0, 255, 0, 255, false, true, 2, false, nil, nil, false)

                if distanceToReturn < 2.0 then
                    ESX.ShowHelpNotification(settings["locales"]["rent_return"])

                    if IsControlJustPressed(1, 51) then
                        ReturnRentalVehicle()
                    end
                end
            end
        end
        Wait(sleep)
    end
end

--[[ Create Blips ]]
local function CreateBlips()
    for _, rent in pairs(settings["rents"]) do
        local blip = AddBlipForCoord(rent.coords.marker.x, rent.coords.marker.y, rent.coords.marker.z)
        SetBlipSprite(blip, 357)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(settings["locales"]["blipname"])
        EndTextCommandSetBlipName(blip)
    end
end

CreateThread(HandleMarkers)
CreateThread(CreateBlips)
