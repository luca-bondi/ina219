#include <Wire.h>
#include "Adafruit_INA219.h"

Adafruit_INA219 ina219;

void setup(void) 
{
  uint32_t currentFrequency;
    
  Serial.begin(115200);
  
  /* Ignore these lines when logging CSV data */
  //Serial.println("Measuring voltage and current with INA219 ...");
  //Serial.println("Timestamp[ms],BusV[V],ShuntV[mV],LoadV[V],Current[mA]");
  ina219.begin();
}

void loop(void) 
{
  float shuntvoltage = 0;
  float busvoltage = 0;
  float current_mA = 0;
  float loadvoltage = 0;

  shuntvoltage = ina219.getShuntVoltage_mV();
  busvoltage = ina219.getBusVoltage_V();
  current_mA = ina219.getCurrent_mA();
  loadvoltage = busvoltage + (shuntvoltage / 1000);
  
  /* CSV output on serial */
  Serial.print(millis());  Serial.print(",");
  Serial.print(busvoltage); Serial.print(",");
  Serial.print(shuntvoltage); Serial.print(",");
  Serial.print(loadvoltage); Serial.print(",");
  Serial.println(current_mA);
  
}

