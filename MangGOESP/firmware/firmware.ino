#include <Wire.h>
#include <VL53L0X.h>
#include <HX711.h>
#include <NimBLEDevice.h>

// =========================
// PIN CONFIGURATION
// =========================

#define HX711_DT 5
#define HX711_SCK 4

#define TOF_SDA 6
#define TOF_SCL 7

#define SERVO_PIN 2
#define BUTTON_PIN 1

// =========================
// SENSOR CONFIGURATION
// =========================

#define SCALE_FACTOR 1047.4
#define SENSOR_TO_BOWL_MM 325.0

HX711 scale;
VL53L0X tof;

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
    MOVING_MANGO,
    MEASURING,
    WAITING_FOR_PHOTO_2,
    COMPLETE
};

MeasurementState state = IDLE;

// =========================
// SERVO
// =========================

void setServoMicroseconds(int us) {

    uint32_t duty =
        (uint32_t)((us / 20000.0) * 65535);

    ledcWrite(SERVO_PIN, duty);
}

void moveServo(int fromUs, int toUs, int durationMs) {

    int steps = 100;

    float step =
        (float)(toUs - fromUs) / steps;

    int delayTime =
        durationMs / steps;

    for (int i = 0; i <= steps; i++) {

        int position =
            fromUs + (step * i);

        setServoMicroseconds(position);

        delay(delayTime);
    }
}

// =========================
// BLE
// =========================

void sendEvent(String message) {

    Serial.print("BLE -> iPhone: ");
    Serial.println(message);

    eventCharacteristic->setValue(
        message.c_str()
    );

    eventCharacteristic->notify();
}

// =========================
// MEASUREMENT
// =========================

float readWeight() {

    const int samples = 10;

    float total = 0;

    for (int i = 0; i < samples; i++) {

        total += scale.get_units(1);

        delay(50);
    }

    return total / samples;
}

float readDistance() {

    const int samples = 10;

    float total = 0;

    for (int i = 0; i < samples; i++) {

        total +=
            tof.readRangeSingleMillimeters();

        delay(50);
    }

    return total / samples;
}

void performMeasurement() {

    Serial.println();
    Serial.println("===== MEASUREMENT =====");

    float weight = readWeight();

    float distance = readDistance();

    float mangoHeight =
        SENSOR_TO_BOWL_MM - distance;

    Serial.print("Weight: ");
    Serial.print(weight, 1);
    Serial.println(" g");

    Serial.print("ToF Distance: ");
    Serial.print(distance, 1);
    Serial.println(" mm");

    Serial.print("Mango Height: ");
    Serial.print(mangoHeight, 1);
    Serial.println(" mm");

    String data =
        "{\"weight\":" +
        String(weight, 1) +
        ",\"distance\":" +
        String(distance, 1) +
        ",\"height\":" +
        String(mangoHeight, 1) +
        "}";

    eventCharacteristic->setValue(
        data.c_str()
    );

    eventCharacteristic->notify();

    Serial.print("BLE -> iPhone: ");
    Serial.println(data);

    Serial.println("=======================");
}

// =========================
// BLE CALLBACKS
// =========================

class CommandCallbacks :
    public NimBLECharacteristicCallbacks {

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

        if (
            command == "PHOTO_1_DONE" &&
            state == WAITING_FOR_PHOTO_1
        ) {
            state = MOVING_MANGO;
        }

        else if (
            command == "PHOTO_2_DONE" &&
            state == WAITING_FOR_PHOTO_2
        ) {
            state = COMPLETE;
        }
    }
};

class ServerCallbacks :
    public NimBLEServerCallbacks {

    void onConnect(
        NimBLEServer* server,
        NimBLEConnInfo& connInfo
    ) override {

        deviceConnected = true;

        Serial.println("iPhone connected!");
    }

    void onDisconnect(
        NimBLEServer* server,
        NimBLEConnInfo& connInfo,
        int reason
    ) override {

        deviceConnected = false;

        Serial.println("iPhone disconnected!");

        NimBLEDevice::getAdvertising()->start();
    }
};

// =========================
// SETUP
// =========================

void setup() {

    Serial.begin(115200);

    delay(1000);

    Serial.println();
    Serial.println("===== MangGO ESP32 =====");

    pinMode(
        BUTTON_PIN,
        INPUT_PULLDOWN
    );

    ledcAttach(
        SERVO_PIN,
        50,
        16
    );

    setServoMicroseconds(500);

    scale.begin(
        HX711_DT,
        HX711_SCK
    );

    scale.set_scale(
        SCALE_FACTOR
    );

    Serial.println("Taring HX711...");

    scale.tare();

    Serial.println("HX711 ready");

    Wire.begin(
        TOF_SDA,
        TOF_SCL
    );

    tof.init();

    tof.setTimeout(500);

    Serial.println("VL53L0X ready");

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

    commandCharacteristic =
        service->createCharacteristic(
            COMMAND_UUID,
            NIMBLE_PROPERTY::WRITE
        );

    commandCharacteristic->setCallbacks(
        new CommandCallbacks()
    );

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

    Serial.println("BLE ready");
    Serial.println("Waiting for iPhone...");
}

// =========================
// LOOP
// =========================

void loop() {

    if (state == IDLE) {

        if (
            digitalRead(BUTTON_PIN) == HIGH &&
            deviceConnected
        ) {

            Serial.println();
            Serial.println("BUTTON PRESSED");

            sendEvent(
                "MEASUREMENT_STARTED"
            );

            delay(300);

            sendEvent(
                "CAPTURE_1"
            );

            state =
                WAITING_FOR_PHOTO_1;

            delay(500);
        }
    }

    else if (state == MOVING_MANGO) {

        Serial.println();
        Serial.println("Moving mango...");

        moveServo(
            500,
            1500,
            2000
        );

        Serial.println(
            "Waiting 5 seconds..."
        );

        delay(5000);

        moveServo(
            1500,
            500,
            2000
        );

        Serial.println(
            "Mango settled."
        );

        delay(1000);

        state = MEASURING;
    }

    else if (state == MEASURING) {

        performMeasurement();

        delay(300);

        sendEvent(
            "CAPTURE_2"
        );

        state =
            WAITING_FOR_PHOTO_2;
    }

    else if (state == COMPLETE) {

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