#include <HX711.h>

#include <NimBLEDevice.h>

// =====================================================
// PIN CONFIGURATION
// =====================================================

#define HX711_DT 4
#define HX711_SCK 5

#define SERVO_PIN 3
#define BUTTON_PIN 6

// =====================================================
// HX711 CALIBRATION
// =====================================================

#define SCALE_FACTOR 1047.4

HX711 scale;

// =====================================================
// BLE
// =====================================================

#define SERVICE_UUID\
    "12345678-1234-1234-1234-123456789000"

#define COMMAND_UUID\
    "12345678-1234-1234-1234-123456789001"

#define EVENT_UUID\
    "12345678-1234-1234-1234-123456789002"

NimBLECharacteristic * commandCharacteristic;
NimBLECharacteristic * eventCharacteristic;

bool deviceConnected = false;

// =====================================================
// HARDWARE STATUS
// =====================================================

bool loadCellReady = false;
bool servoReady = false;

// =====================================================
// HARDWARE MONITOR TIMER
// =====================================================

unsigned long lastHardwareCheck = 0;

const unsigned long HARDWARE_CHECK_INTERVAL = 1000;

// =====================================================
// STATE MACHINE
// =====================================================

enum MeasurementState {
    IDLE,
    WAITING_FOR_PHOTO_1,
    MOVING_MANGO,
    MEASURING,
    WAITING_FOR_PHOTO_2,
    COMPLETE
};

MeasurementState state = IDLE;

// =====================================================
// SERVO
// =====================================================

void setServoMicroseconds(int us) {

    uint32_t duty =
        (uint32_t)((us / 20000.0) * 65535);

    ledcWrite(SERVO_PIN, duty);
}

void moveServo(
    int fromUs,
    int toUs,
    int durationMs
) {

    const int steps = 100;

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

// =====================================================
// BLE SEND
// =====================================================

void sendEvent(String message) {

    if (!deviceConnected) {

        Serial.println(
            "BLE not connected"
        );

        return;
    }

    Serial.print(
        "ESP32 -> iPhone: "
    );

    Serial.println(message);

    eventCharacteristic -> setValue(
        message.c_str()
    );

    eventCharacteristic -> notify();
}

// =====================================================
// HARDWARE STATUS
// =====================================================

void sendHardwareStatus() {

    if (!deviceConnected) {
        return;
    }

    if (loadCellReady) {

        sendEvent(
            "LOAD_CELL_READY"
        );

    } else {

        sendEvent(
            "LOAD_CELL_OFFLINE"
        );
    }

    if (servoReady) {

        sendEvent(
            "SERVO_READY"
        );

    } else {

        sendEvent(
            "SERVO_OFFLINE"
        );
    }


    if (loadCellReady && servoReady) {

        sendEvent(
            "HARDWARE_READY"
        );
    }
}

// =====================================================
// CHECK LOAD CELL
// =====================================================

bool checkLoadCell() {

    /*
     * HX711 should respond to this.
     *
     * If DT / SCK / power is disconnected,
     * this should normally return false.
     */

    return scale.wait_ready_timeout(100);
}

// =====================================================
// REAL-TIME HARDWARE MONITOR
// =====================================================

void checkHardware() {

    bool previousLoadCell =
        loadCellReady;

    bool previousServo =
        servoReady;

    // -------------------------------------------------
    // LOAD CELL
    // -------------------------------------------------

    loadCellReady =
        checkLoadCell();

    // -------------------------------------------------
    // SERVO
    // -------------------------------------------------

    /*
     * IMPORTANT:
     *
     * ESP32 cannot detect a disconnected servo signal
     * wire from an output GPIO.
     *
     * For now, servoReady means:
     *
     * "Servo subsystem was initialized successfully."
     *
     * Later, if you add current/feedback sensing,
     * replace this with a real physical check.
     */

    servoReady = true;

    // -------------------------------------------------
    // REPORT ONLY WHEN STATUS CHANGES
    // -------------------------------------------------

    if (
        previousLoadCell !=
        loadCellReady
    ) {

        if (loadCellReady) {

            Serial.println(
                "⚖️ LOAD CELL ONLINE"
            );

            sendEvent(
                "LOAD_CELL_READY"
            );

        } else {

            Serial.println(
                "❌ LOAD CELL OFFLINE"
            );

            sendEvent(
                "LOAD_CELL_OFFLINE"
            );
        }
    }

    if (
        previousServo !=
        servoReady
    ) {

        if (servoReady) {

            Serial.println(
                "⚙️ SERVO ONLINE"
            );

            sendEvent(
                "SERVO_READY"
            );

        } else {

            Serial.println(
                "❌ SERVO OFFLINE"
            );

            sendEvent(
                "SERVO_OFFLINE"
            );
        }
    }
}

// =====================================================
// HX711
// =====================================================

float readWeight() {

    const int samples = 10;

    float total = 0;

    for (int i = 0; i < samples; i++) {

        total += scale.get_units(1);

        delay(50);
    }

    return total / samples;
}

// =====================================================
// MEASUREMENT
// =====================================================

void performMeasurement() {

    Serial.println();
    Serial.println(
        "===== MEASUREMENT ====="
    );

    // Don't measure if HX711 isn't available

    if (!loadCellReady) {

        Serial.println(
            "❌ Cannot measure: HX711 offline"
        );

        return;
    }

    float weight = readWeight();

    Serial.print("Weight: ");
    Serial.print(weight, 1);
    Serial.println(" g");

    String data =
        "{\"weight\":" +
        String(weight, 1) +
        "}";

    sendEvent(data);

    Serial.println(
        "======================="
    );
}

// =====================================================
// BLE COMMAND CALLBACK
// =====================================================

class CommandCallbacks
    : public NimBLECharacteristicCallbacks {

        void onWrite(
            NimBLECharacteristic * characteristic,
            NimBLEConnInfo & connInfo
        ) override {

            std::string value =
                characteristic -> getValue();

            String command =
                String(value.c_str());

            Serial.print(
                "iPhone -> ESP32: "
            );

            Serial.println(command);

            // -------------------------------------------------
            // PHOTO 1 COMPLETED
            // -------------------------------------------------

            if (command == "PHOTO_1_DONE") {

                if (
                    state ==
                    WAITING_FOR_PHOTO_1
                ) {

                    Serial.println(
                        "Photo 1 confirmed"
                    );

                    state =
                        MOVING_MANGO;
                }
            }

            // -------------------------------------------------
            // PHOTO 2 COMPLETED
            // -------------------------------------------------
            else if (
                command == "PHOTO_2_DONE"
            ) {

                if (
                    state ==
                    WAITING_FOR_PHOTO_2
                ) {

                    Serial.println(
                        "Photo 2 confirmed"
                    );

                    state =
                        COMPLETE;
                }
            }
            else if (command == "REQUEST_HARDWARE_STATUS") {
                Serial.println(
                    "Hardware status requested by iPhone"
                );
                sendHardwareStatus();
            }
        }
    };

// =====================================================
// BLE SERVER CALLBACK
// =====================================================

class ServerCallbacks
    : public NimBLEServerCallbacks {

        void onConnect(
            NimBLEServer * server,
            NimBLEConnInfo & connInfo
        ) override {

            deviceConnected = true;

            Serial.println();
            Serial.println(
                "📱 iPhone connected!"
            );

            // Give hardware monitor a moment

            delay(100);

            // Check hardware immediately

            loadCellReady =
                checkLoadCell();

            /*
             * Servo currently has no physical feedback.
             */

            servoReady = true;

            Serial.println();

            if (loadCellReady) {
                Serial.println(
                    "⚖️ HX711: READY"
                );

            } else {

                Serial.println(
                    "❌ HX711: OFFLINE"
                );
            }

            if (servoReady) {

                Serial.println(
                    "⚙️ Servo: READY"
                );

            } else {

                Serial.println(
                    "❌ Servo: OFFLINE"
                );
            }

            Serial.println();

            // Send current state to iPhone

            sendHardwareStatus();
        }
    void onDisconnect(
        NimBLEServer * server,
        NimBLEConnInfo & connInfo,
        int reason
    ) override {

        deviceConnected = false;

        Serial.println(
            "📱 iPhone disconnected!"
        );

        NimBLEDevice::getAdvertising()->start();
    }
};

// =====================================================
// SETUP
// =====================================================

void setup() {

    Serial.begin(115200);

    delay(1000);

    Serial.println();
    Serial.println(
        "======================"
    );

    Serial.println(
        "MangGO ESP32"
    );

    Serial.println(
        "======================"
    );

    // =================================================
    // BUTTON
    // =================================================

    pinMode(
        BUTTON_PIN,
        INPUT_PULLDOWN
    );

    // =================================================
    // SERVO
    // =================================================

    ledcAttach(
        SERVO_PIN,
        50,
        16
    );

    setServoMicroseconds(500);

    servoReady = true;

    Serial.println(
        "⚙️ Servo initialized"
    );

    // =================================================
    // HX711
    // =================================================

    scale.begin(
        HX711_DT,
        HX711_SCK
    );

    scale.set_scale(
        SCALE_FACTOR
    );

    Serial.println(
        "Checking HX711..."
    );

    if (
        scale.wait_ready_timeout(1000)
    ) {

        Serial.println(
            "⚖️ HX711 ready"
        );

        scale.tare();

        Serial.println(
            "HX711 tared"
        );

        loadCellReady = true;

    } else {

        Serial.println(
            "❌ ERROR: HX711 not found"
        );

        loadCellReady = false;
    }

    // =================================================
    // BLE
    // =================================================

    NimBLEDevice::init(
        "MangGO-ESP32"
    );

    NimBLEServer * server =
        NimBLEDevice::createServer();

    server -> setCallbacks(
        new ServerCallbacks()
    );

    NimBLEService * service =
        server -> createService(
            SERVICE_UUID
        );

    // -------------------------------------------------
    // iPhone -> ESP32
    // -------------------------------------------------

    commandCharacteristic =
        service -> createCharacteristic(
            COMMAND_UUID,
            NIMBLE_PROPERTY::WRITE
        );

    commandCharacteristic -> setCallbacks(
        new CommandCallbacks()
    );

    // -------------------------------------------------
    // ESP32 -> iPhone
    // -------------------------------------------------

    eventCharacteristic =
        service -> createCharacteristic(
            EVENT_UUID,
            NIMBLE_PROPERTY::NOTIFY
        );

    service -> start();

    // =================================================
    // BLE ADVERTISING
    // =================================================

    NimBLEAdvertising * advertising =
        NimBLEDevice::getAdvertising();

    advertising -> addServiceUUID(
        SERVICE_UUID
    );

    advertising -> start();

    Serial.println(
        "BLE ready"
    );

    Serial.println(
        "Device name: MangGO-ESP32"
    );

    Serial.println(
        "Waiting for iPhone..."
    );
}

// =====================================================
// LOOP
// =====================================================

void loop() {

    // =================================================
    // REAL-TIME HARDWARE CHECK
    // =================================================

    if (
        millis() -
        lastHardwareCheck >=
        HARDWARE_CHECK_INTERVAL
    ) {

        lastHardwareCheck =
            millis();

        checkHardware();
    }

    // =================================================
    // IDLE
    // =================================================

    if (state == IDLE) {

        if (
            digitalRead(BUTTON_PIN) == HIGH &&
            deviceConnected
        ) {

            // Safety check before starting

            if (!loadCellReady) {

                Serial.println(
                    "❌ Cannot start: "
                    "Load cell offline"
                );

                delay(500);

                return;
            }

            if (!servoReady) {

                Serial.println(
                    "❌ Cannot start: "
                    "Servo offline"
                );

                delay(500);

                return;
            }

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

            delay(500);
        }
    }

    // =================================================
    // MOVE MANGO
    // =================================================
    else if (
        state == MOVING_MANGO
    ) {

        // Check hardware before moving

        checkHardware();

        if (!servoReady) {

            Serial.println(
                "❌ Servo offline. "
                "Stopping movement."
            );

            state = IDLE;

            delay(500);

            return;
        }

        Serial.println();
        Serial.println(
            "Moving mango..."
        );

        // 500us -> 1500us

        moveServo(
            500,
            1500,
            2000
        );

        Serial.println(
            "Waiting 1 seconds..."
        );

        delay(1000);

        // Return to start

        moveServo(
            1500,
            500,
            300
        );

        Serial.println(
            "Mango settled"
        );

        delay(1000);

        state =
            MEASURING;
    }

    // =================================================
    // MEASUREMENT
    // =================================================
    else if (
        state == MEASURING
    ) {

        checkHardware();

        if (!loadCellReady) {

            Serial.println(
                "❌ Load cell offline."
            );

            state = IDLE;

            delay(500);

            return;
        }

        performMeasurement();

        delay(300);

        sendEvent(
            "CAPTURE_2"
        );

        state =
            WAITING_FOR_PHOTO_2;
    }

    // =================================================
    // COMPLETE
    // =================================================
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

        state =
            IDLE;

        delay(1000);
    }

    delay(20);
}