How to use the Google Sign-in Feature -> using @IBAction func signInWithGoogle(_ sender: UIButton) method 
+ Put these 2 lines in viewDidLoad() method
    + let mainDelegate = UIApplication.shared.delegate as! AppDelegate
    + mainDelegate.setupGoogleSignIn()
+ Copy this IBAction Function to the new ViewController
+ Come to AppDelegate, change the "segueIdentiferForSignIn" variable to the segue identifier name that you want
+ All user information is saved in AppDelegate




How to use the "checkCredentials() function" to check "entered credentials" 

    + Step 1: Access to AppDelegate
    let mainDelegate = UIApplication.shared.delegate as! AppDelegate
    
    + Step 2: Call the function inside a Task{} according to this syntax. Pass 2 string into the functions for username and password. Right now, we have username as "abc1" and password as "123" in database
    Task {
        let success = await mainDelegate.checkCredentials(userNameEntered: username.text!, passwordEntered: password.text!)
    }
    // if the sign-in process is successful, the function will return true

    --> Example 
    @IBAction func signIn(_ sender: UIButton) {
        let mainDelegate = UIApplication.shared.delegate as! AppDelegate
        Task {
            let success = await mainDelegate.checkCredentials(userNameEntered: username.text!, passwordEntered: password.text!)
            if success {
                performSegue(withIdentifier: mainDelegate.segueIdentiferForSignIn, sender: nil)
                mainDelegate.isLoggedIn = true
            }
        }
    }




Access Test
+ chakshita can push the code successfully
+ joshuajocson can push the code successfully

