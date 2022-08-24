//
//  ListViewController.swift
//  TravelBook
//
//  Created by Berkay Kuzu on 22.08.2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var titleArray = [String]()
    var idArray = [UUID]()
    var chosenTitle = ""
    var chosenTitleId : UUID?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        tableView.dataSource = self
        tableView.delegate = self
        
        navigationItem.title = "My Travel Book" //Uygulamamıza başlık ekledik.
        
        getData() // En son olarak getData() fonksiyonunu viewDidLoad altında çağırdım.
    }
    
    override func viewWillAppear(_ animated: Bool) { //Bir önceki ekrana döndük!
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    // CoreData'daki verileri çekip tableView'da gösteriyorum
    
    @objc func getData() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
           
            if results.count > 0 { /* results'ın içinde bir şey var mı diye kontrol ediyoruz, eğer result'ın içinde bir şey varsa şunu şunu yap diyoruz.*/
                
                self.titleArray.removeAll(keepingCapacity: false) /* for loop'a girmeden önce duplicate verilerin olmasını engelliyor.*/
                self.idArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject] { /* Any'i NSManagedObject olarak cast ettik bu sayade CoreData metodlarına ulaştık*/
                    
                    
                    if let title = result.value(forKey: "title") as? String {
                        self.titleArray.append(title)
                    }
                    
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    
                    tableView.reloadData() // Bütün verileri tableView içerisinde göstereceğimiz için tableView.reloadData() yazdık
                }
                
            }
        } catch {
            print("error")
        }
        
    }
    
    @objc func addButtonClicked() {
        chosenTitle = ""
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count // title array'ın sayısı kadar row yapar.
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row] // titleArraydeki row da ne varsa onu göster.
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { //Her bir hücreye tıklayınca diğer sayfaya git!
        chosenTitle = titleArray[indexPath.row]
        chosenTitleId = idArray [indexPath.row]
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedTitleId = chosenTitleId
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
           
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = idArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString) //Böylece sadece id ile çağırabiliyoruz!
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
               
                if results.count > 0 { /* results'ın içinde bir şey var mı diye kontrol ediyoruz, eğer result'ın içinde bir şey varsa şunu şunu yap diyoruz.*/
                    for result in results as! [NSManagedObject] {
                        
                        if let id = result.value(forKey: "id") as? UUID {
                            
                            if id == idArray[indexPath.row] {
                                context.delete(result)
                                titleArray.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                do {
                                    try context.save()
                                    
                                } catch {
                                    print("error")
                                }
                              
                                break
                            }
                        }
                    }
                    
                }
            } catch {
                print("error")
            }
        }
    }
}
