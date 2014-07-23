class MS5607 {
    _i2c  = null;
    static PADDR = 0xec;
    static READD1 = "\x48";
    static READD2 = "\x58";
    static READADC = "\x00";
    static READCAL = "\xa2";
    static C = array(8);
    
    constructor(i2c) {
        _i2c  = i2c;
        _i2c.configure(CLOCK_SPEED_100_KHZ);
    }
   
    function GetTemp() {
        _i2c.write(PADDR, READD2);
        imp.sleep(0.05);
        _i2c.write(PADDR, READADC);
        imp.sleep(0.05);
        local a = _i2c.read((PADDR+1), "", 3);
        local D2=a[0]*65536 + a[1]*256 + a[2];
        //server.log(C[5]);
        local dT = D2 - (C[5]*256);
        //server.log(dT);
        local Temp = dT * (C[6].tofloat()/128);
        //server.log(Temp);
        Temp =(Temp /65536) + 2000;
        //server.log(format("Temp: %d %d %d %d",a[0],a[1],a[2],Temp));
        return Temp/100;
    }
    
    function GetPress() {
        _i2c.write(PADDR, READD2);
        imp.sleep(0.05);
        _i2c.write(PADDR, READADC);
        imp.sleep(0.05);
        local a = _i2c.read((PADDR+1), "", 3);
        local D2=a[0]*65536 + a[1]*256 + a[2];
        _i2c.write(PADDR, READD1);
        imp.sleep(0.05);
        _i2c.write(PADDR, READADC);
        imp.sleep(0.05);
        local a = _i2c.read((PADDR+1), "", 3);
        local D1=a[0]*65536 + a[1]*256 + a[2];
        //server.log(D1);
        local dT = D2 - (C[5]*256);
        //server.log(dT);
        local Temp = dT * (C[6].tofloat()/128);
        //server.log(Temp);
        Temp =(Temp /65536) + 2000;
        
        local OFF = C[2].tofloat()*65536+dT*C[4].tofloat()/128;
        //server.log(OFF);
        local SENS = C[1].tofloat()*32768+dT*C[3].tofloat()/256;
        //server.log(SENS);
        if(Temp<2000) {
          local T1 = dT * dT /2147483648;
          local OFF1 = 5 * (Temp-2000) *(Temp-2000)/2;
          local SENS1 = 5 * (Temp-2000) *(Temp-2000)/4;
          
          if ( Temp< -1500) {
            OFF1 = OFF1 + 7 * (Temp+1500) * (Temp+1500);
            SENS1 = SENS1 + 11 * (Temp+1500) * (Temp+1500)/2;
          }
          TEMP-=T1;
          OFF-=OFF1;
          SENS-=SENS1;
          
        }
        local Press = (D1.tofloat()*SENS/(65536*32)-OFF)/16384;
        //server.log(format("Press: %d %d %d %d",a[0],a[1],a[2],Press));
        return Press/100;
    }
    
    function GetCal() {
        local i,t,s;
        for (i=0; i<8 ; i++) {
          t=0xa0+(i*2);
          s=t.tochar();
          _i2c.write(PADDR,s);
          imp.sleep(0.05);
          local a = _i2c.read((PADDR+1), "", 2);
          //server.log(a);
          C[i]=a[0]*256+a[1];
          //server.log( format("%d %d %d %d",i, a[0],a[1],C[i]));
        }  
      }
}

pSensor<-MS5607(hardware.i2c89); 
pSensor.GetCal();
server.log(pSensor.GetTemp());
server.log(pSensor.GetPress());

