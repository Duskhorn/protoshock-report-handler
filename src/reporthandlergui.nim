import wNim/[wApp, wFrame, wIcon, wBitmap, wImage, wPanel, wTextCtrl, wButton, wCheckBox, wStaticBitmap, wStaticText, wEvent, wMessageDialog] 
import httpclient, json, times, osproc, strutils, uri, net, base64

const ICON = staticRead("assets/icon.ico")
const HEADER = staticRead("assets/header.jpg")
const WEB = staticRead("secret/web").strip()

let
    app = App(wSystemDpiAware)
    win = Frame(title = "Protoshock Crash Report Tool", size = (640, 480))
    panel = Panel(win)
    text = StaticText(panel, label = "Write your crash report here", style = wAlignCenter or wAlignMiddle)
    area = TextCtrl(panel, style = wTeMultiLine, size = (100, 100))
    send = Button(panel, label = "Send Report", size = (50, 50))
    info = CheckBox(panel, label = "Include PC specs in the crash report")
    header = HEADER.Image.Icon.Bitmap
    head = StaticBitmap(panel, bitmap = header)
    icon = Image(ICON)

win.icon = Icon(icon)

panel.backgroundColor = wBlack
text.backgroundColor = wGrey

info.setValue(true)

area.foregroundColor = wWhite
area.backgroundColor = wDarkGrey

proc layout() = 
    panel.autolayout """
        spacing: 8
        H:|-[head]-|
        H:|-[text]-|
        H:|-[area]-|
        H:|-[info]-|
        H:|-[send]-|
        V:|-[head(45%)]-[text]-2-[area]-[info(5%)]-[send(5%)]-|
    """

proc getDeviceInfo(): string = 
    proc wmic(s, k: string): string =
        let (output, _) = execCmdEx("wmic " & s & " get " & k, options = {poDaemon, poEvalCommand})
        return output.strip.split("\n")[^1]

    return 
        "OS name:\t\t" & wmic("os", "name").split("|")[0]  & "\n" &
        "OS version:\t\t" & wmic("os", "version")  & "\n" &
        "CPU name:\t\t" & wmic("cpu", "Name")  & "\n" &
        "CPU vendor:\t\t" & wmic("cpu", "manufacturer")  & "\n" &
        "CPU clock (GHz):\t\t" & $(parseFloat(wmic("cpu", "MaxClockSpeed")) / 1000.0) & "\n" &
        "RAM total (GB):\t\t" & $(parseInt(wmic("computersystem", "TotalPhysicalMemory")) / 1024 / 1024 / 1024) & "\n" &
        "RAM free:\t\t" & $(parseInt(wmic("os", "FreePhysicalMemory")) / 1024 / 1024 / 1024) & "\n" &
        "GPU name:\t\t" & wmic("path win32_VideoController", "name") & "\n" &
        "GPU driver:\t\t" & wmic("path win32_VideoController", "DriverVersion") & "\n" &
        "GPU max FPS:\t\t" & wmic("path win32_VideoController", "MaxRefreshRate")      

proc sendReport(text: string, info_flag: wId) =
    var client = newhttpclient(
        userAgent = "pshock-bug-launch: vbeta; platform: win32; Mozilla: 5.0;",
        headers = newHttpHeaders({"Content-Type" : "application/x-www-form-urlencoded"})
    )

    let
        info = 
            if info_flag == wIdYes:
                getDeviceInfo()
            else: ""
        date = now().utc        
        body = encodeQuery({"error_json" : $ %*{
                "device_info": info.encode(),
                "bug_report": text,
                "date": $date.year & "-" & $date.month & "-" & $date.monthday,
                "time": $date.hour & ":" & $date.minute & ":" & $date.second
            }
        }, false)

    echo $body

    try:
        let response = client.request(WEB, httpMethod = HttpPost, body = body)
        echo "server response was: ", response.status
        echo response.body
    finally: client.close()

panel.wEvent_Size do ():
  layout()

send.wEvent_Button do (): 
    var confirm: wId
    if info.getValue():
        let msg = MessageDialog(win, caption = "Are you sure you want to send your PC data?", message = " Here's what we'll collect:\nOS name, version;\nCPU name, vendor, clock frequency;\ntotal and free RAM;\nGPU name, driver version and max FPS allowed by GPU", style = wYesNo or wIconQuestion)
        confirm = msg.showModal()

    let t = area.getValue()
    send.label = "Sending report..."     
    sendReport(t, confirm)
    win.close()

layout()
win.center()
win.show()
app.mainLoop()