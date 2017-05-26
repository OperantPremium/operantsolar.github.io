/**                                                                            
 * (C) 2017 Operant Solar
 * All rights reserved
 *
 * @author: Rama Nadendla <rama.nadendla@operantsolar.com>
 * 
 */

/**
 * Make a global function to log a message to the console which works with
 * standard Squirrel or on the Imp.
 * @param {string} message The message to log.
 */
if (!("consoleLog" in getroottable()))
{
  consoleLog <- function(message)
  {
    if ("server" in getroottable())
      server.log(message);
    else
      print(message); print("\n");
  }
}

const auchCRCHi = "\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40";

// blob of CRC values for low–order byte
const auchCRCLo = "\x00\xC0\xC1\x01\xC3\x03\x02\xC2\xC6\x06\x07\xC7\x05\xC5\xC4\x04\xCC\x0C\x0D\xCD\x0F\xCF\xCE\x0E\x0A\xCA\xCB\x0B\xC9\x09\x08\xC8\xD8\x18\x19\xD9\x1B\xDB\xDA\x1A\x1E\xDE\xDF\x1F\xDD\x1D\x1C\xDC\x14\xD4\xD5\x15\xD7\x17\x16\xD6\xD2\x12\x13\xD3\x11\xD1\xD0\x10\xF0\x30\x31\xF1\x33\xF3\xF2\x32\x36\xF6\xF7\x37\xF5\x35\x34\xF4\x3C\xFC\xFD\x3D\xFF\x3F\x3E\xFE\xFA\x3A\x3B\xFB\x39\xF9\xF8\x38\x28\xE8\xE9\x29\xEB\x2B\x2A\xEA\xEE\x2E\x2F\xEF\x2D\xED\xEC\x2C\xE4\x24\x25\xE5\x27\xE7\xE6\x26\x22\xE2\xE3\x23\xE1\x21\x20\xE0\xA0\x60\x61\xA1\x63\xA3\xA2\x62\x66\xA6\xA7\x67\xA5\x65\x64\xA4\x6C\xAC\xAD\x6D\xAF\x6F\x6E\xAE\xAA\x6A\x6B\xAB\x69\xA9\xA8\x68\x78\xB8\xB9\x79\xBB\x7B\x7A\xBA\xBE\x7E\x7F\xBF\x7D\xBD\xBC\x7C\xB4\x74\x75\xB5\x77\xB7\xB6\x76\x72\xB2\xB3\x73\xB1\x71\x70\xB0\x50\x90\x91\x51\x93\x53\x52\x92\x96\x56\x57\x97\x55\x95\x94\x54\x9C\x5C\x5D\x9D\x5F\x9F\x9E\x5E\x5A\x9A\x9B\x5B\x99\x59\x58\x98\x88\x48\x49\x89\x4B\x8B\x8A\x4A\x4E\x8E\x8F\x4F\x8D\x4D\x4C\x8C\x44\x84\x85\x45\x87\x47\x46\x86\x82\x42\x43\x83\x41\x81\x80\x40";

class Modbus {
    _driver = null;
    _rtsPin = null;

    // this is the liength of time we will do the action reading on modbus (in ms)
    // may need to updated to a new number if it is longer.
    _readTimeLength = 100;
    _baudRate = 9600;

    constructor (baudRate=9600) {
        _baudRate= baudRate;
         if (debugEnable) consoleLog("<DBUG>Set Modbus Baud rate to: " + _baudRate + " </DBUG>");
        initialize();
    }

    function setReadTimeLnegth (timeLength) {
        _readTimeLength = timeLength;
    }

    // Initialize the modbus driver, configure the driver and the pin
    function initialize() {
        // Modbus Initialization
        //Alias the uart1
        _driver = hardware.uart1;
        //Configure the uart, leave it at 2400 baud rate to avoid issues.
        _driver.configure(_baudRate, 8, PARITY_NONE, 1, NO_CTSRTS );
        // Imp setup : Modbus hardware driver needs an RTS signal to set output enable
        _rtsPin = hardware.pinG;
        _rtsPin.configure(DIGITAL_OUT, 0);
    }

    // Write the included string to the Modbus, a character at a time
    function writeCommand(cmd) {
        //strip any white space in the front or back.
        cmd = strip(cmd);

        // post error message, the cmd string needs to be even length.
        if (cmd.len() % 2 != 0 && debugEnable ) consoleLog("<DBUG>Command string needs to even length</DBUG>");

        //set up a local blob for writing to UART
        local cmdBlob = blob();

        // we parse this into a blob containing the byte values of each pair of hex digits
        // and write that single byte value to the blob
        for (local i = 0 ; i < cmd.len() ; i += 2) {
            // two characters in the hex string equal one value in the blob
            // turn a pair of hex characters into a single byte value
            local byteValue = ImpUtilities.hexToInteger(cmd.slice(i, i+2));
            // write that byte value into the blob
            cmdBlob.writen(byteValue, 'b');
        }

        // Now we have the blob in writable format, send it to calculate the CRC
        // Calculated CRC16 in string form
        local calculatedCRC = ImpUtilities.hexConvert(CRC16(cmdBlob, 6),2);

        // need the Hi and Lo bytes in integer form to add to blob for output
        local crcHi = ImpUtilities.hexToInteger(calculatedCRC.slice(0,2));
        local crcLo = ImpUtilities.hexToInteger(calculatedCRC.slice(2,4));

        cmdBlob.writen(crcHi,'b');  // write that byte value into the blob
        cmdBlob.writen(crcLo,'b');  // write that byte value into the blob

        // Actually send to UART
        // raise RTS to enable the Modbus driver
        _rtsPin.write(1);
	if (debugEnable) {
	  consoleLog("<DBUG>");
	  consoleLog(cmdBlob);
	  consoleLog("</DBUG>");
	}
        _driver.flush();
        _driver.write(cmdBlob);
        // wait until write done to unassert RTS
        _driver.flush(); 
        // lower RTS to change back to receive mode for inverter reply
        _rtsPin.write(0); 
    }

    function baudRateToMicros() {
        return (1000000/_baudRate);
    }

    // Read data from UART FIFO
    function readResult() {

        local result = "";
        local byteVal = 0;
        // read failure timeout
        local readTimer = hardware.millis();
        local readWaitMicros = hardware.micros();
        local baudRateWait = baudRateToMicros();

         while ((hardware.millis() - readTimer) < _readTimeLength) {
            //wait for the hardware.micros() for atleast a bit period + margin
            //sleep for 10micros to avoid tight spin
            while (hardware.micros() < readWaitMicros + baudRateWait) {
                imp.sleep(0.000010);
            }

            byteVal = _driver.read();
            readWaitMicros = hardware.micros();

            // skip -1's indicates empty UART FIFO
            if (byteVal != -1 ) {
                result += format("%.2X",byteVal);
            }
            
        }
        if (result == ""){ 
            result = "01030400000000FA33";
            }
            
        if (debugEnable) consoleLog("<DBUG> Modbus result " + result + "</DBUG>");
        return  result;
    }

    // Example 2 - Translated from MODBUS over serial line specification and implementation
    // guide V1.02 (Appendix B)- C Implementation
    // http://modbus.com/docs/Modbus_over_serial_line_V1_02.pdf
    // This code uses a lookup table so should be faster but uses more memory
    // blob of CRC values for high–order byte

    function CRC16 ( puchMsg, usDataLen ){
        //unsigned char *puchMsg ; // message to calculate CRC upon
        //unsigned short usDataLen ; // quantity of bytes in message
        local uchCRCHi = 0xFF ; // high byte of CRC initialized
        local uchCRCLo = 0xFF ; // low byte of CRC initialized
        local uIndex ; // will index into CRC lookup table
        local i = 0;
        while (usDataLen--){ // pass through message buffer
            uIndex = uchCRCLo ^ puchMsg[i] ; // calculate the CRC
            uchCRCLo = uchCRCHi ^ auchCRCHi[uIndex] ;
            uchCRCHi = auchCRCLo[uIndex] ;
            i++
        }
        //return (uchCRCHi << 8 | uchCRCLo) ;
            return (uchCRCLo << 8 | uchCRCHi) ;
    }    
}
