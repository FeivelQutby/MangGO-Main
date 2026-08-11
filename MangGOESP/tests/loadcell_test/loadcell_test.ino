#include "HX711.h"

#define HX711_DT 5
#define HX711_SCK 4

HX711 scale;

void setup() {
    Serial.begin(115200);
    delay(1000);

    Serial.println("HX711 Load Cell Test");

    scale.begin(HX711_DT, HX711_SCK);

    delay(500);

    if (scale.is_ready()) {
        Serial.println("HX711 connected!");

        scale.set_scale(-1047.4);

        Serial.println("Taring...");
        scale.tare();

        Serial.println("Ready!");
    } else {
        Serial.println("HX711 not found!");
    }
}

void loop() {
    if (scale.is_ready()) {

        float weight = scale.get_units(10);
        weight = weight * -1;

        Serial.print("Weight: ");
        Serial.print(weight, 1);
        Serial.println(" g");

    } else {
        Serial.println("HX711 not ready...");
    }

    delay(150);
}