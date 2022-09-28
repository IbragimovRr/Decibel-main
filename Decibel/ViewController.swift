//
//  ViewController.swift
//  Decibel
//
//  Created by Руслан on 03.09.2022.
//

import UIKit
import CoreLocation
import AVFAudio
import Charts
import FirebaseFirestore
import FirebaseStorage
import AVFoundation
import CoreLocation


class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, ChartViewDelegate, CLLocationManagerDelegate {
    
    var arrayAudio = Array<Audio>()
    var dateStart = ""
    var time = 0
    
    var timer2:Timer!
    
    let locationManager = CLLocationManager()
    @IBOutlet weak var compasView: UIView!
    @IBOutlet weak var nameGradus: UILabel!
    @IBOutlet weak var gradus: UILabel!
    @IBOutlet weak var compas: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var chartLast: UIView!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var avrGraphickDb: UILabel!
    @IBOutlet weak var maxGraphickDb: UILabel!
    @IBOutlet weak var viewGlavn: UIView!
    @IBOutlet weak var viewGraphick2: UIView!
    @IBOutlet weak var constrant2niz: NSLayoutConstraint!
    @IBOutlet weak var second20: UILabel!
    @IBOutlet weak var first20: UILabel!
    @IBOutlet weak var second10: UILabel!
    @IBOutlet weak var first10: UILabel!
    @IBOutlet weak var secondm10: UILabel!
    @IBOutlet weak var firstm10: UILabel!
    @IBOutlet weak var avrDb: UILabel!
    @IBOutlet weak var maxDb: UILabel!
    @IBOutlet weak var nowDb: UILabel!
    @IBOutlet weak var viewGr: UIView!
    @IBOutlet weak var imConstant: NSLayoutConstraint!
    @IBOutlet weak var ViewGraphick: NSLayoutConstraint!
    @IBOutlet weak var imGraphick: UIImageView!
    //loc
    let locManager = CLLocationManager()
    var currentLocation:CLLocation!
    
    var maximum = 0
    var arrayAverage = Array<Int>()
    private var resultlast = 0.0
    
    var ran = 0
    //audio
    var player : AVAudioPlayer!
    private var audioRecorder = AVAudioRecorder()
    var recordingSession: AVAudioSession!
    
    private var timer:Timer!
    
    
    let db = Firestore.firestore()
    //chart
    let marker = MarkerImage()
    var arrayAverageCharts = Array<ChartDataEntry>()
    var arrayAverageChartsBar = Array<BarChartDataEntry>()
    @IBOutlet weak var recOn: UIButton!
    @IBOutlet weak var rec: UIButton!
    @IBOutlet weak var nowMin: UILabel!
    @IBOutlet weak var now20: UILabel!
    @IBOutlet weak var now: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addAudio()
        self.overrideUserInterfaceStyle = .light
        self.navigationController?.navigationBar.isHidden = true
        locManager.requestWhenInUseAuthorization()
        addMicro()
        location()
        
        timer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(startMonitoring), userInfo: nil, repeats: true)
        timer.fire()
        reChartLiner()
        reChartBar()
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    private func addAudio(){
        db.collection(UIDevice.current.identifierForVendor!.uuidString).addSnapshotListener() { qs, err in
            if err != nil{
                print(err?.localizedDescription)
            }else{
                self.arrayAudio.removeAll()
                for documents in qs!.documents{
                    let data = documents.data()
                    
                    let url = data["url"] as? String ?? ""
                    let start = data["start"] as? String ?? ""
                    let end = data["end"] as? String ?? ""
                    let max = data["max"] as? String ?? ""
                    let avg = data["avg"] as? String ?? ""
                    let time = data["time"] as? String ?? ""
                    
                    self.arrayAudio.append(Audio(url: url, start: start, end: end, max: max, avg: avg, time: time))
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func reChartBar(){
        barChartView.rightAxis.enabled = false
        let yAxis = barChartView.leftAxis
        yAxis.setLabelCount(11, force: true)
        yAxis.labelFont = .systemFont(ofSize: 10)
        yAxis.labelTextColor = .white.withAlphaComponent(0.6)
        barChartView.xAxis.labelPosition = .bottom
        barChartView.xAxis.labelTextColor = .white.withAlphaComponent(0.6)
        barChartView.xAxis.labelFont = .systemFont(ofSize: 10)
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.xAxis.drawAxisLineEnabled = false
        barChartView.leftAxis.drawAxisLineEnabled = false
        barChartView.leftAxis.gridLineDashLengths = [5]
        barChartView.leftAxis.gridColor = .gray.withAlphaComponent(0.2)
        barChartView.doubleTapToZoomEnabled = false
        barChartView.pinchZoomEnabled = false
        barChartView.scaleXEnabled = false
        barChartView.scaleYEnabled = false
    }
    
    func reChartLiner(){
        lineChartView.rightAxis.enabled = false
        let yAxis = lineChartView.leftAxis
        yAxis.setLabelCount(11, force: true)
        yAxis.labelFont = .systemFont(ofSize: 10)
        yAxis.labelTextColor = .white.withAlphaComponent(0.6)
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.labelTextColor = .white.withAlphaComponent(0.6)
        lineChartView.xAxis.labelFont = .systemFont(ofSize: 10)
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.xAxis.drawAxisLineEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        lineChartView.leftAxis.gridLineDashLengths = [5]
        lineChartView.leftAxis.gridColor = .gray.withAlphaComponent(0.2)
        lineChartView.doubleTapToZoomEnabled = false
        lineChartView.pinchZoomEnabled = false
        lineChartView.scaleXEnabled = false
        lineChartView.scaleYEnabled = false
        
    }
    @objc func startMonitoring(){
        audioRecorder.updateMeters()
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        let db = audioRecorder.peakPower(forChannel: 0)
        let res = pow(10.0, db / 20.0) * 120.0
        let r = -80 + 6 * log2(res)
        let result = r + 120
        resultlast = Double(pow(10.0, db / 20.0) * 120.0)
        if Int(round(result)) > 0{
        nowDb.text = "\(Int(round(result))) dB"
            arrayAverage.append(Int(round(result)))
            
            
            chartLiner()
            chartBar()
            
            var content = 0
            for a in arrayAverage {
                content += a
            }
            avrGraphickDb.text = "\(Int(round(Double(content/arrayAverage.count)))) dB"
            avrDb.text = "\(Int(round(Double(content/arrayAverage.count)))) dB"
            first10.text = "\(Int(round(result))+10)"
            second10.text = "\(Int(round(result))+10)"
            first20.text = "\(Int(round(result))+20)"
            second20.text = "\(Int(round(result))+20)"
            firstm10.text = "\(Int(round(result))-10)"
            secondm10.text = "\(Int(round(result))-10)"
            if Int(round(result)) > maximum {
                maximum = Int(round(result))
                maxDb.text = "\(maximum) dB"
                maxGraphickDb.text = "\(maximum) dB"
            }
        }
    }
    
    func addMicro(){
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String:Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        do {
            recc()
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [])
            
            startMonitoring()
        } catch {
            fatalError(error.localizedDescription)
        }
        
    }
    
    
    private func chartLiner(){
        marker.image = UIImage(named: "marker")
        lineChartView.drawMarkers = true
        lineChartView.marker = marker
      
        
        
        
        
        arrayAverageCharts.removeAll()
        for x in 0...arrayAverage.count-1 {
            arrayAverageCharts.append(ChartDataEntry(x: Double("\(x).0")!,
                                                     y:Double(arrayAverage[x]) ))
        }
        let set1 = LineChartDataSet(entries: arrayAverageCharts, label: "")
        set1.drawCirclesEnabled = false
        set1.mode = .cubicBezier
        set1.lineWidth = 4
        set1.drawFilledEnabled = true
        set1.drawHorizontalHighlightIndicatorEnabled = false
        
        let gradientColors = [UIColor.systemMint.cgColor, UIColor.clear.cgColor] as CFArray // Colors of the gradient
        let colorLocations:[CGFloat] = [0.2, 0.0] // Positioning of the gradient
        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) // Gradient Object
        set1.fill = LinearGradientFill(gradient: gradient!, angle: 90.0)// Set the Gradient
        set1.drawFilledEnabled = true // Draw the Gradient
        let data = LineChartData(dataSet: set1)
        data.setDrawValues(false)
        lineChartView.data = data
    }
    
    private func chartBar(){
        arrayAverageChartsBar.removeAll()
        for x in 0...arrayAverage.count-1 {
            arrayAverageChartsBar.append(BarChartDataEntry(x: Double("\(x).0")!,
                                                        y:Double(arrayAverage[x])))
        }
        let set1 = BarChartDataSet(entries: arrayAverageChartsBar, label: "")
        
        let color1 = [NSUIColor(cgColor: UIColor.systemMint.cgColor)]
        set1.colors = color1
        let data = BarChartData(dataSet: set1)
        data.setDrawValues(false)
        barChartView.data = data
    }

    
    
    
    
    func recc(){
        recordingSession = AVAudioSession.sharedInstance()

        do {
            
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            try recordingSession.overrideOutputAudioPort(.speaker)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("nice")
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
    }
    
    
    
    
    /*func playSound() {
        
        do {
            var ur = ""
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            db.collection("audio").getDocuments { qs, err in
                if err != nil {
                    print(err?.localizedDescription)
                }else{
                    for document in qs!.documents{
                        let data = document.data()
                        let audio = data["audio"] as? String ?? ""
                        ur = audio
                    }
                }
            }
            var preview = URL(fileURLWithPath: "file:///var/mobile/Containers/Data/Application/B92BE774-684F-4FD5-AA3A-A46689BC704F/Documents/13795310myRecording.m4a")
            preview = getFileUrl(random: ran)
            player = try AVAudioPlayer(contentsOf: getFileUrl(random: ran), fileTypeHint: AVFileType.m4a.rawValue)
                    self.player.play()
                } catch let error {
                    print("Error:", error.localizedDescription)
            guard let player = player else { return }
            player.play()
        } catch let error {
            
            print(error.localizedDescription)
        }
    }*/
    
    
    
    
    func startRecording() {
        print("uhiu")
        print(ran)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: getFileUrl(random: ran), settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            audioRecorder.updateMeters()
            audioRecorder.isMeteringEnabled = true
        
                
            
            
        } catch {
            finishRecording(success: false)
        }
    }
    
    
    
    func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func getFileUrl(random:Int) -> URL
    {
        
        let filename = "\(random)myRecording.m4a"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
    return filePath
    }
    
    
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        

        if success {
            print("nice")
        } else {
            print("failed")
            // recording failed :(
        }
    }
    
    
    
    func location(){
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() ==  .authorizedAlways {
            currentLocation = locManager.location
            let loc = Int(round(currentLocation.altitude))
            now.text = "\(loc)"
            now20.text = "\(loc+20)"
            nowMin.text = "\(loc-20)"
        }
    }

    
    
    @IBAction func Rec(_ sender: UIButton) {
        compasView.isHidden = false
        time = 0
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        
        timer2 = .scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
        
        dateStart = dateString
        
        let random = Int.random(in: 0...100000000)
        print("\(random)-------")
        ran = random
        rec.isHidden = true
        recOn.isHidden = false
        audioRecorder.prepareToRecord()
        startRecording()
        if (CLLocationManager.headingAvailable()) {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
            locationManager.delegate = self
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {

        let heading: CLLocationDirection = ((newHeading.trueHeading > 0) ?
                    newHeading.trueHeading : newHeading.magneticHeading)
        gradus.text = "\(Int(round(heading)))°"
        var strDirection = String()
                if(heading > 23 && heading <= 67){
                    strDirection = "NE"
                } else if(heading > 68 && heading <= 112){
                    strDirection = "E"
                } else if(heading > 113 && heading <= 167){
                    strDirection = "SE"
                } else if(heading > 168 && heading <= 202){
                    strDirection = "S"
                } else if(heading > 203 && heading <= 247){
                    strDirection = "SW"
                } else if(heading > 248 && heading <= 293){
                    strDirection = "W"
                } else if(heading > 294 && heading <= 337){
                    strDirection = "NW"
                } else if(heading >= 338 || heading <= 22){
                    strDirection = "N"
                }
        UIView.animate(withDuration: 0.5) {
            let angle = CGFloat(heading) * .pi / 180 // convert from degrees to radians
                    self.compas.transform = CGAffineTransform(rotationAngle: -angle) // rotate the picture
                }
        nameGradus.text = strDirection
    }
    
    
    @IBAction func RecOn(_ sender: UIButton) {
        let max = maxDb.text
        let avg = avrDb.text
        
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        
        timer2?.invalidate()

        let start = dateStart
        let end = dateString
        
        
        rec.isHidden = false
        recOn.isHidden = true
        finishRecording(success: true)
        let data = [
            "url":"\(ran)myRecording.m4a",
            "start":start,
            "end":end,
            "avg":avg,
            "max":max,
            "time":"\(time) сек"
            
        ] as [String : Any]
        db.collection("\(UIDevice.current.identifierForVendor!.uuidString)").addDocument(data: data)
        compasView.isHidden = true
    }
    
    @objc func updateCounter() {
        time += 1
    }

    

    @IBAction func Graphick(_ sender: UIButton) {
        if sender.tag == 0{
            
            view.layoutIfNeeded()
            UIView.animate(withDuration: 1, delay: 0.0) {
                
                self.ViewGraphick.constant = -220
                self.constrant2niz.constant = 40
                self.view.layoutIfNeeded()
            }
            
            self.imGraphick.image = UIImage(named: "graphick2")
            self.imConstant.constant = 0
            st.isHidden = false
            sender.tag = 1
        }else{
            
            view.layoutIfNeeded()
            UIView.animate(withDuration: 1) {
                self.ViewGraphick.constant = -92
                self.constrant2niz.constant = 20
                self.view.layoutIfNeeded()
            }
            
            imGraphick.image = UIImage(named: "Graphics")
            imConstant.constant = -110
            st.isHidden = true
            sender.tag = 0
        }
        
        
    }
    
    
    
    @IBOutlet weak var niz: UIButton!
    @IBOutlet weak var st: UIStackView!
    
    
    @IBAction func graphick(_ sender: UIButton) {
        viewGraphick2.isHidden = false
        maxGraphickDb.isHidden = false
        avrGraphickDb.isHidden = false
        viewGlavn.isHidden = true
        UIView.animate(withDuration: 1) {
            self.ViewGraphick.constant = -92
            self.constrant2niz.constant = 20
            self.view.layoutIfNeeded()
        }
        st.isHidden = true
        imGraphick.image = UIImage(named: "dbGraphick")
        niz.isEnabled = false
        
        if sender.tag == 0 || sender.tag == 1{
            lineChartView.isHidden = false
            barChartView.isHidden = true
            chartLast.isHidden = true
        }else if sender.tag == 2{
            barChartView.isHidden = false
            lineChartView.isHidden = true
            chartLast.isHidden = true
        }else if sender.tag == 3{
            chartLast.isHidden = false
            barChartView.isHidden = true
            lineChartView.isHidden = true
        }
    }

    
    
    
}
extension ViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayAudio.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Audio", for: indexPath) as! ShumTableViewCell
        cell.end.text = arrayAudio[indexPath.row].end
        cell.nach.text = arrayAudio[indexPath.row].start
        cell.avgdB.text = "AVG \(arrayAudio[indexPath.row].avg)"
        cell.maxDb.text = "MAX \(arrayAudio[indexPath.row].max)"
        cell.time.text = arrayAudio[indexPath.row].time
        return cell
    }
    
    
}

