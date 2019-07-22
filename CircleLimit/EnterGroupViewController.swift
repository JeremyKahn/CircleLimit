//
//  EnterGroupViewController.swift
//  CircleLimit
//
//  Created by Jeremy Adam Kahn on 10/8/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

class EnterGroupViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var orbifold: UILabel!
    
    @IBAction func done(_ sender: UIButton) {
        print("Done")
        delegate.enterGroupString = orbifold.text!
        dismiss(animated: true, completion: nil)
    }

    var delegate: EnterGroupDelegate!
    
    // TODO: Grey out buttons when they're not permitted by the strict notation. 
    @IBAction func inputFromButton(_ sender: UIButton) {
        orbifold.text! += sender.titleLabel!.text!
    }
    
    @IBAction func backspace(_ sender: UIButton) {
        orbifold.text!.removeLast()
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

protocol EnterGroupDelegate {
    var enterGroupString: String {get set}
}
