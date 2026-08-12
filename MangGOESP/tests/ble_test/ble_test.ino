#include <NimBLEDevice.h>

// =========================
// BUTTON
// =========================

#define BUTTON_PIN 5

// =========================
// BLE
// =========================

#define SERVICE_UUID \
"12345678-1234-1234-1234-123456789000"

#define COMMAND_UUID \
"12345678-1234-1234-1234-123456789001"

#define EVENT_UUID \
"12345678-1234-1234-1234-123456789002"

NimBLECharacteristic* commandCharacteristic;
NimBLECharacteristic* eventCharacteristic;

bool deviceConnected = false;

// =========================
// STATE MACHINE
// =========================

enum MeasurementState {
    IDLE,
    WAITING_FOR_PHOTO_1,
    SIMULATING_MEASUREMENT,
    WAITING_FOR_PHOTO_2,
    COMPLETE
};

MeasurementState state = IDLE;

// =========================
// BLE EVENTS
// =========================

void sendEvent(String message) {

    if (!deviceConnected) {
        Serial.println("BLE not connected");
        return;
    }

    Serial.print("ESP32 -> iPhone: ");
    Serial.println(message);

    eventCharacteristic->setValue(
        message.c_str()
    );

    eventCharacteristic->notify();
}

// =========================
// DUMMY MEASUREMENT
// =========================

void sendDummyMeasurement() {

    float weight = 482.5;
    float distance = 259.8;
    float height = 65.2;

    String data =
        "{\"weight\":" +
        String(weight, 1) +
        ",\"distance\":" +
        String(distance, 1) +
        ",\"height\":" +
        String(height, 1) +
        "}";

    sendEvent(data);
}

// =========================
// BLE COMMAND CALLBACK
// =========================

class CommandCallbacks
    : public NimBLECharacteristicCallbacks {

    void onWrite(
        NimBLECharacteristic* characteristic,
        NimBLEConnInfo& connInfo
    ) override {

        std::string value =
            characteristic->getValue();

        String command =
            String(value.c_str());

        Serial.print("iPhone -> ESP32: ");
        Serial.println(command);

        if (command == "PHOTO_1_DONE") {

            if (state == WAITING_FOR_PHOTO_1) {

                Serial.println(
                    "Photo 1 confirmed"
                );

                state =
                    SIMULATING_MEASUREMENT;
            }
        }

        else if (command == "PHOTO_2_DONE") {

            if (state == WAITING_FOR_PHOTO_2) {

                Serial.println(
                    "Photo 2 confirmed"
                );

                state = COMPLETE;
            }
        }
    }
};

// =========================
// BLE SERVER CALLBACK
// =========================

class ServerCallbacks
    : public NimBLEServerCallbacks {

    void onConnect(
        NimBLEServer* server,
        NimBLEConnInfo& connInfo
    ) override {

        deviceConnected = true;

        Serial.println();
        Serial.println(
            "iPhone connected!"
        );
    }

    void onDisconnect(
        NimBLEServer* server,
        NimBLEConnInfo& connInfo,
        int reason
    ) override {

        deviceConnected = false;

        Serial.println(
            "iPhone disconnected!"
        );

        NimBLEDevice::
            getAdvertising()->start();
    }
};

// =========================
// SETUP
// =========================

void setup() {

    Serial.begin(115200);

    delay(1000);

    Serial.println();
    Serial.println("======================");
    Serial.println("MangGO BLE Test");
    Serial.println("======================");

    pinMode(
        BUTTON_PIN,
        INPUT_PULLDOWN
    );

    // BLE
    NimBLEDevice::init(
        "MangGO-ESP32"
    );

    NimBLEServer* server =
        NimBLEDevice::createServer();

    server->setCallbacks(
        new ServerCallbacks()
    );

    NimBLEService* service =
        server->createService(
            SERVICE_UUID
        );

    // iPhone -> ESP32
    commandCharacteristic =
        service->createCharacteristic(
            COMMAND_UUID,
            NIMBLE_PROPERTY::WRITE
        );

    commandCharacteristic->setCallbacks(
        new CommandCallbacks()
    );

    // ESP32 -> iPhone
    eventCharacteristic =
        service->createCharacteristic(
            EVENT_UUID,
            NIMBLE_PROPERTY::NOTIFY
        );

    service->start();

    NimBLEAdvertising* advertising =
        NimBLEDevice::getAdvertising();

    advertising->addServiceUUID(
        SERVICE_UUID
    );

    advertising->start();

    Serial.println(
        "BLE started!"
    );

    Serial.println(
        "Device name: MangGO-ESP32"
    );

    Serial.println(
        "Waiting for iPhone..."
    );
}

// =========================
// LOOP
// =========================

void loop() {

    // =========================
    // IDLE
    // =========================

    if (state == IDLE) {

        if (
            digitalRead(BUTTON_PIN) == HIGH
            && deviceConnected
        ) {

            Serial.println();
            Serial.println(
                "BUTTON PRESSED"
            );

            sendEvent(
                "MEASUREMENT_STARTED"
            );

            delay(300);

            sendEvent(
                "CAPTURE_1"
            );

            state =
                WAITING_FOR_PHOTO_1;

            // Prevent repeated trigger
            delay(500);
        }
    }

    // =========================
    // DUMMY MEASUREMENT
    // =========================

    else if (
        state == SIMULATING_MEASUREMENT
    ) {

        Serial.println();
        Serial.println(
            "Simulating measurement..."
        );

        // Simulate sensor/mechanism delay
        delay(3000);

        sendDummyMeasurement();

        delay(300);

        sendEvent(
            "CAPTURE_2"
        );

        state =
            WAITING_FOR_PHOTO_2;
    }

    // =========================
    // COMPLETE
    // =========================

    else if (
        state == COMPLETE
    ) {

        sendEvent(
            "MEASUREMENT_COMPLETE"
        );

        Serial.println();
        Serial.println(
            "===== COMPLETE ====="
        );

        state = IDLE;

        delay(1000);
    }

    delay(20);
}