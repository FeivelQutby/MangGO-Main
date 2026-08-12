#include <Wire.h>
#include <VL53L0X.h>

VL53L0X sensor;

#define SDA_PIN 5
#define SCL_PIN 4

const int NUM_SAMPLES = 20;

// Known distance from ToF to bowl bottom
const float BOWL_DISTANCE_MM = 325.0;

void setup() {
    Serial.begin(115200);

    Wire.begin(SDA_PIN, SCL_PIN);

    if (!sensor.init()) {
        Serial.println("VL53L0X not found!");
        while (1);
    }

    sensor.setTimeout(500);

    Serial.println("VL53L0X Ready");
}

void loop() {

    long total = 0;
    int validSamples = 0;

    // Take 20 readings
    for (int i = 0; i < NUM_SAMPLES; i++) {

        int distance = sensor.readRangeSingleMillimeters();

        if (!sensor.timeoutOccurred()) {
            total += distance;
            validSamples++;
        }

        delay(50);
    }

    if (validSamples > 0) {

        float averageDistance =
            (float)total / validSamples;

        // Calculate mango height
        float calibratedDistance = averageDistance - 66.0;

        float mangoHeight = BOWL_DISTANCE_MM - calibratedDistance;

        Serial.print("ToF Distance: ");
        Serial.print(averageDistance, 1);
        Serial.println(" mm");

        Serial.print("Mango Height: ");
        Serial.print(mangoHeight, 1);
        Serial.println(" mm");

        Serial.println("--------------------");

    } else {
        Serial.println("No valid readings");
    }

    delay(500);
}