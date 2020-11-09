import Foundation
import CoreMIDI
import PlaygroundSupport

func getDisplayName(_ obj: MIDIObjectRef) -> String {
    var param: Unmanaged<CFString>?
    var name: String = "Error"
    let err: OSStatus = MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &param)
    if err == OSStatus(noErr) {
        name =  param!.takeRetainedValue() as String
    }
    return name
}

func getDestinationNames() -> [String] {
    var names:[String] = [];
    let count: Int = MIDIGetNumberOfDestinations();
    for i in 0..<count {
        let endpoint:MIDIEndpointRef = MIDIGetDestination(i);
        if (endpoint != 0) {
            names.append(getDisplayName(endpoint));
        }
    }
    return names;
}

func getSourceNames() -> [String] {
    var names:[String] = [];
    let count: Int = MIDIGetNumberOfSources();
    for i in 0..<count {
        let endpoint:MIDIEndpointRef = MIDIGetSource(i);
        if (endpoint != 0) {
            names.append(getDisplayName(endpoint));
        }
    }
    return names;
}

let destNames = getDestinationNames();

print("Number of MIDI Destinations: \(destNames.count)");
for destName in destNames
{
    print("  Destination: \(destName)");
}

let sourceNames = getSourceNames();

print("\nNumber of MIDI Sources: \(sourceNames.count)");
for sourceName in sourceNames
{
    print("  Source: \(sourceName)");
}

func MyMIDIReadProc(pktList: UnsafePointer<MIDIPacketList>,
                    readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) -> Void
{
    let packetList:MIDIPacketList = pktList.pointee
    let srcRef:MIDIEndpointRef = srcConnRefCon!.load(as: MIDIEndpointRef.self)

    print("MIDI Received From Source: \(getDisplayName(srcRef))")

    var packet:MIDIPacket = packetList.packet
    for _ in 1...packetList.numPackets
    {
        let bytes = Mirror(reflecting: packet.data).children
        var dumpStr = ""

        // bytes mirror contains all the zero values in the ridiulous packet data tuple
        // so use the packet length to iterate.
        var i = packet.length
        for (_, attr) in bytes.enumerated()
        {
            dumpStr += String(format:"$%02X ", attr.value as! UInt8)
            i -= 1
            if (i <= 0)
            {
                break
            }
        }

        print(dumpStr)
        packet = MIDIPacketNext(&packet).pointee
    }
}

var midiClient: MIDIClientRef = 0
var inPort:MIDIPortRef = 0
var src:MIDIEndpointRef = MIDIGetSource(0)

MIDIClientCreate("MidiTestClient" as CFString, nil, nil, &midiClient)
MIDIInputPortCreate(midiClient, "MidiTest_InPort" as CFString, MyMIDIReadProc, nil, &inPort)
MIDIPortConnectSource(inPort, src, &src)

// Keep playground running
PlaygroundPage.current.needsIndefiniteExecution = true
