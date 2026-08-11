#define SERVO_PIN 3
#define BUTTON_PIN 4

void setServoMicroseconds(int us) {
    uint32_t duty = (uint32_t)((us / 20000.0) * 65535);
    ledcWrite(SERVO_PIN, duty);
}

void moveServo(int startUs, int endUs, int durationMs) {
    int steps = 100;
    int stepDelay = durationMs / steps;

    for (int i = 0; i <= steps; i++) {
        int currentUs = startUs + ((endUs - startUs) * i / steps);

        setServoMicroseconds(currentUs);
        delay(stepDelay);
    }
}

void setup() {
    Serial.begin(115200);

    ledcAttach(SERVO_PIN, 50, 16);

    pinMode(BUTTON_PIN, INPUT);

    // Start position
    setServoMicroseconds(500);

    Serial.println("Ready!");
}

void loop() {

    if (digitalRead(BUTTON_PIN) == HIGH) {

        Serial.println("Button pressed!");

        // 500 → 1500 in 2 seconds
        Serial.println("Opening...");
        moveServo(500, 1500, 1000);

        // Stay at 1500 for 5 seconds
        Serial.println("Waiting 3 seconds...");
        delay(3000);

        // 1500 → 500 in 2 seconds
        Serial.println("Returning...");
        moveServo(1500, 500, 1000);

        Serial.println("Ready!");

        // Wait until button is released
        while (digitalRead(BUTTON_PIN) == HIGH) {
            delay(10);
        }
    }
}