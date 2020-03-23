//
//  ViewController.swift
//  TipCalculator
//
//  Created by Desmond Gee on 3/21/20.
//  Copyright © 2020 Desmond Gee. All rights reserved.
//

import UIKit

@objcMembers class ViewController: UIViewController {
    @IBOutlet weak var totalAfterTaxField: UITextField!
    @IBOutlet weak var itemTotalField: UITextField!
    @IBOutlet weak var person1ItemTotalField: UITextField!
    @IBOutlet weak var person2ItemTotalField: UITextField!
    
    
    @IBOutlet weak var payTip: UILabel!
    @IBOutlet weak var payTotal: UILabel!
    @IBOutlet weak var tipPercent: UILabel!
    @IBOutlet weak var taxPercent: UILabel!
    @IBOutlet weak var bothPercent: UILabel!
    
    @IBOutlet weak var tipSelector: UIPickerView!
    
    let tipPercents = ["0%", "1%", "2%", "3%", "4%", "5%", "6%", "7%", "8%", "9%", "10%", "11%", "12%", "13%", "14%", "15%", "16%", "17%", "18%", "19%", "20%", "22%", "22%", "24%", "26%", "28%", "30%", "35%", "40%", "45%", "50%", "75%", "100%", "150%", "200%"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tipSelector.delegate = self
        
        totalAfterTaxField.addTarget(self, action: #selector(currencyFieldChanged), for: .editingChanged)
        itemTotalField.addTarget(self, action: #selector(currencyFieldChanged), for: .editingChanged)
        person1ItemTotalField.addTarget(self, action: #selector(currencyFieldChanged), for: .editingChanged)
        person2ItemTotalField.addTarget(self, action: #selector(currencyFieldChanged), for: .editingChanged)
        
        tipSelector.selectRow(7, inComponent:0, animated:true)
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        
        view.addGestureRecognizer(tap)
    }
    
    func currencyFieldChanged(_ textField: UITextField) {
        if let amountString = textField.text?.formatDollars(max_dollar_digits: 4) {
            textField.text = amountString
        }
        
        updateCalculations()
    }
    
    func updateCalculations() {
        let tipCents = (tipMultiplier * Decimal(afterTaxCents)).rounded
        payTip.text = tipCents.formattedDollars
        
        let payTotalCents = afterTaxCents + tipCents
        payTotal.text = payTotalCents.formattedDollars

        if (afterTaxCents > 0 && itemTotalCents > 0 && afterTaxCents >= itemTotalCents) {
            let taxCents = afterTaxCents - itemTotalCents
            let taxRatio = Double(taxCents) / Double(itemTotalCents)
            taxPercent.text = taxRatio.formatPercent(precision: 2)
            
            let tipRatio = Double(tipCents) / Double(itemTotalCents)
            tipPercent.text = tipRatio.formatPercent(precision: 2)
            
            let bothRatio = (Double(payTotalCents) / Double(itemTotalCents) - 1)
            bothPercent.text = bothRatio.formatPercent(precision: 2)
        }
        else {
            tipPercent.text = "???"
            taxPercent.text = "???"
            bothPercent.text = "???"
        }
    }
    
    var tipMultiplier: Decimal {
        let tipString = rawTipPercent
        
        let end = tipString.index(tipString.endIndex, offsetBy: -1)
        let tipNumber = Int(tipString[..<end]) ?? 0
        return Decimal(tipNumber) * 0.01
    }
    
    var rawTipPercent: String {
        if let selector = tipSelector {
            return tipPercents[selector.selectedRow(inComponent: 0)]
        }
        else {
            return "0%"
        }
    }
    
    var afterTaxCents: Int {
        if let text = totalAfterTaxField.text {
            return text.cents
        }
        else {
            return 0
        }
    }
    
    var itemTotalCents: Int {
        if let text = itemTotalField.text {
            return text.cents
        }
        else {
            return 0
        }
    }
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return tipPercents.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        updateCalculations() // updates calculations while scrolling instead of just waiting for it to stop
        return tipPercents[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateCalculations()
    }
    
}

extension String {
    // formatting text for currency textField
    func formatDollars(max_dollar_digits: Double? = nil) -> String {

        var number: NSNumber!
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        var amountWithPrefix = self

        // remove from String: "$", ".", ","
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count), withTemplate: "")

        var double = (amountWithPrefix as NSString).doubleValue
        
        if let digits = max_dollar_digits {
            let max_value = pow(10, digits + 2) // +2 for cents
            while (double >= max_value) {
                let remainder = double.truncatingRemainder(dividingBy: 10)
                double = double - remainder
                double = double * 0.1
            }
        }
            
        number = NSNumber(value: (double / 100))

        // if first number is 0 or all numbers were deleted
        guard number != 0 as NSNumber else {
            return ""
        }

        return formatter.string(from: number)!
    }
    
    var cents: Int {
        var amountWithPrefix = self

        // remove from String: "$", ".", ","
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count), withTemplate: "")

        return (amountWithPrefix as NSString).integerValue
    }
}

extension Decimal {
    var formattedDollars: String? {
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let numberText = formatter.string(from: self as NSDecimalNumber) ?? "0.00"
        return "$" + numberText
    }
    
    var rounded: Int {
        NSDecimalNumber(decimal: self).intValue
    }
    
    // Assumes self is in dollars
    func convertToCents() -> Int {
        return NSDecimalNumber(decimal: self * 100).intValue
    }
}

extension Double {
    func formatPercent(precision: Int) -> String {
        if self >= 100 || self < 0 {
         return "???"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumIntegerDigits = 1
        formatter.maximumIntegerDigits = 5
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        
        if let string = formatter.string(from: NSNumber(value: self)) {
            return string
        }
        else {
            return "0%"
        }
    }
}

extension Int {
    // Assumes self is in cents
    var formattedDollars: String {
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let dollars = Decimal(self) * 0.01
        let numberText = formatter.string(from: dollars as NSDecimalNumber) ?? "0.00"
        let string = numberText.formatDollars()
        if string == "" {
            return "$0.00"
        }
        else {
            return string
        }
    }
}
