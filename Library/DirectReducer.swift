//
//  DefaultAppReducer.swift
//  GlucoseDirect
//

import Combine
import Foundation
import UIKit

// MARK: - directReducer

func directReducer(state: inout DirectState, action: DirectAction) {
    switch action {
    case .addCalibration(bloodGlucoseValue: let bloodGlucoseValue):
        guard let latestRawGlucoseValue = state.latestSensorGlucose?.rawGlucoseValue else {
            DirectLog.info("Guard: state.currentGlucose.initialGlucoseValue is nil")
            break
        }
        
        state.customCalibration.append(CustomCalibration(x: Double(latestRawGlucoseValue), y: Double(bloodGlucoseValue)))
        
    case .addGlucose(glucoseValues: let addedGlucoseValues):
        var glucoseValues: [Glucose]
            
        let overLimit = state.glucoseValues.count + addedGlucoseValues.count - DirectConfig.numberOfGlucoseValues
        if overLimit > 0 {
            glucoseValues = Array(state.glucoseValues.dropFirst(overLimit) + addedGlucoseValues)
        } else {
            glucoseValues = state.glucoseValues + addedGlucoseValues
        }
        
        state.glucoseValues = glucoseValues
        state.latestGlucose = glucoseValues.last
        state.latestBloodGlucose = glucoseValues.last(where: { $0.isBloodGlucose })
        state.latestSensorGlucose = glucoseValues.last(where: { $0.isSensorGlucose || $0.isFaultyGlucose })
        state.missedReadings = 0
        
    case .addMissedReading:
        state.missedReadings += 1
        
    case .addSensorReadings:
        break
        
    case .bellmanTestAlarm:
        break
        
    case .clearCalibrations:
        state.customCalibration = []
        
    case .clearGlucoseValues:
        state.glucoseValues = []
        state.latestGlucose = nil
        state.latestBloodGlucose = nil
        state.latestSensorGlucose = nil
        
    case .connectConnection:
        break
        
    case .deleteLogs:
        break

    case .disconnectConnection:
        break

    case .pairConnection:
        break
        
    case .registerConnectionInfo(infos: let infos):
        state.connectionInfos.append(contentsOf: infos)
        
    case .removeCalibration(calibration: let calibration):
        state.customCalibration = state.customCalibration.filter { item in
            item.id != calibration.id
        }
        
    case .removeGlucose(glucose: let glucose):
        state.glucoseValues = state.glucoseValues.filter { item in
            item.id != glucose.id
        }
        
    case .requestAppleCalendarAccess(enabled: _):
        break
        
    case .requestAppleHealthAccess(enabled: _):
        break
        
    case .resetSensor:
        state.sensor = nil
        state.customCalibration = []
        state.connectionError = nil
        state.connectionErrorIsCritical = false
        state.connectionErrorTimestamp = nil
        
    case .selectCalendarTarget(id: let id):
        state.selectedCalendarTarget = id
        
    case .selectConnection(id: let id, connection: let connection):
        if id != state.selectedConnectionID || state.selectedConnection == nil {
            state.selectedConnectionID = id
            state.selectedConnection = connection
        }
        
    case .selectConnectionID(id: _):
        state.isConnectionPaired = false
        state.sensor = nil
        state.transmitter = nil
        state.customCalibration = []
        state.connectionError = nil
        state.connectionErrorIsCritical = false
        state.connectionErrorTimestamp = nil
        
    case .selectView(viewTag: let viewTag):
        state.selectedView = viewTag
        
    case .sendLogs:
        break
        
    case .setAlarmHigh(upperLimit: let upperLimit):
        state.alarmHigh = upperLimit

    case .setAlarmLow(lowerLimit: let lowerLimit):
        state.alarmLow = lowerLimit

    case .setAlarmSnoozeUntil(untilDate: let untilDate, autosnooze: let autosnooze):
        if let untilDate = untilDate {
            state.alarmSnoozeUntil = untilDate
        } else {
            state.alarmSnoozeUntil = nil
        }
        
        if !autosnooze {
            DirectNotifications.shared.stopSound()
        }
        
    case .setAppleCalendarExport(enabled: let enabled):
        state.appleCalendarExport = enabled
        
    case .setAppleHealthExport(enabled: let enabled):
        state.appleHealthExport = enabled
        
    case .setBellmanConnectionState(connectionState: let connectionState):
        state.bellmanConnectionState = connectionState
        
    case .setBellmanNotification(enabled: let enabled):
        state.bellmanAlarm = enabled
           
    case .setChartShowLines(enabled: let enabled):
        state.chartShowLines = enabled
        
    case .setChartZoomLevel(level: let level):
        state.chartZoomLevel = level
        
    case .setConnectionAlarmSound(sound: let sound):
        state.connectionAlarmSound = sound
        
    case .setConnectionError(errorMessage: let errorMessage, errorTimestamp: let errorTimestamp, errorIsCritical: let errorIsCritical):
        state.connectionError = errorMessage
        state.connectionErrorTimestamp = errorTimestamp
        state.connectionErrorIsCritical = errorIsCritical
        
    case .setConnectionPaired(isPaired: let isPaired):
        state.isConnectionPaired = isPaired
        
    case .setConnectionPeripheralUUID(peripheralUUID: let peripheralUUID):
        state.connectionPeripheralUUID = peripheralUUID
        
    case .setConnectionState(connectionState: let connectionState):
        state.connectionState = connectionState

        if resetableStates.contains(connectionState) {
            state.connectionError = nil
            state.connectionErrorIsCritical = false
            state.connectionErrorTimestamp = nil
        }
        
    case .setExpiringAlarmSound(sound: let sound):
        state.expiringAlarmSound = sound
               
    case .setGlucoseNotification(enabled: let enabled):
        state.glucoseNotification = enabled
        
    case .setGlucoseUnit(unit: let unit):
        state.glucoseUnit = unit
        
    case .setHighGlucoseAlarmSound(sound: let sound):
        state.highGlucoseAlarmSound = sound
        
    case .setIgnoreMute(enabled: let enabled):
        state.ignoreMute = enabled
        
    case .setLowGlucoseAlarmSound(sound: let sound):
        state.lowGlucoseAlarmSound = sound

    case .setNightscoutSecret(apiSecret: let apiSecret):
        state.nightscoutApiSecret = apiSecret

    case .setNightscoutUpload(enabled: let enabled):
        state.nightscoutUpload = enabled
        
    case .setNightscoutURL(url: let url):
        state.nightscoutURL = url
        
    case .setPreventScreenLock(enabled: let enabled):
        state.preventScreenLock = enabled

    case .setReadGlucose(enabled: let enabled):
        state.readGlucose = enabled
        
    case .setSensor(sensor: let sensor, keepDevice: let keepDevice):
        if let sensorSerial = state.sensor?.serial, sensorSerial != sensor.serial {
            state.customCalibration = []
            
            if !keepDevice {
                state.connectionPeripheralUUID = nil
            }
        }
        
        state.sensor = sensor
        state.connectionError = nil
        state.connectionErrorIsCritical = false
        state.connectionErrorTimestamp = nil
        
    case .setSensorInterval(interval: let interval):
        state.sensorInterval = interval

    case .setSensorState(sensorAge: let sensorAge, sensorState: let sensorState):
        guard state.sensor != nil else {
            DirectLog.info("Guard: state.sensor is nil")
            break
        }
        
        state.sensor!.age = sensorAge
        
        if let sensorState = sensorState {
            state.sensor!.state = sensorState
        }
        
        if state.sensor!.startTimestamp == nil {
            state.sensor!.startTimestamp = Date() - Double(sensorAge) * 60
        }

    case .setTransmitter(transmitter: let transmitter):
        state.transmitter = transmitter
               
    case .startup:
        break
    }

    if let alarmSnoozeUntil = state.alarmSnoozeUntil, Date() > alarmSnoozeUntil {
        state.alarmSnoozeUntil = nil
    }
}

// MARK: - private

private var resetableStates: Set<SensorConnectionState> = [.connected, .powerOff, .scanning]
private var disconnectedStates: Set<SensorConnectionState> = [.disconnected, .scanning]