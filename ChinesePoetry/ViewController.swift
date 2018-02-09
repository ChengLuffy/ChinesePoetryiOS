//
//  ViewController.swift
//  ChinesePoetry
//
//  Created by 成殿 on 2018/2/8.
//  Copyright © 2018年 成殿. All rights reserved.
//

import UIKit
import SVProgressHUD

enum Type: String {
    case title
    case author
    case txt
}

class ViewController: UIViewController {
    
    lazy var dataSource: [PoetryModel] = [PoetryModel]()
    var keyword: String = ""
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        SVProgressHUD.setDefaultStyle(.light)
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setMaximumDismissTimeInterval(1.25)
        view.addSubview(tableView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showAlertVC()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["tableView": tableView]
        let tableViewHC = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[tableView]-|", options: [], metrics: nil, views: views)
        var tableViewVC = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[tableView]-|", options: [], metrics: nil, views: views)
        
        if #available(iOS 11.0, *) {
            let metrics = ["bottomAnchor": view.safeAreaInsets.bottom] as [String : Any]
            tableViewVC = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[tableView]-bottomAnchor-|", options: [], metrics: metrics, views: views)
        }
        
        view.addConstraints(tableViewHC)
        view.addConstraints(tableViewVC)
    }
    
    func showAlertVC() {
        let alertVC = UIAlertController(title: "唐诗宋词关键词🔍", message: "输入关键词，并选择相应的类型", preferredStyle: .alert)
        alertVC.addTextField { (tf) in
            tf.delegate = self
        }
        
        let authorAction = UIAlertAction(title: "🔍作者", style: .default) { (_) in
            self.searchPoetry(by: .author, name: self.keyword)
        }
        let titleAction = UIAlertAction(title: "🔍标题", style: .default) { (_) in
            self.searchPoetry(by: .title, name: self.keyword)
        }
        let txtAction = UIAlertAction(title: "🔍内容", style: .default) { (_) in
            self.searchPoetry(by: .txt, name: self.keyword)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (_) in
            
        }
        
        alertVC.addAction(authorAction)
        alertVC.addAction(titleAction)
        alertVC.addAction(txtAction)
        alertVC.addAction(cancelAction)
        
        present(alertVC, animated: true) {
        }
    }
    
    @IBAction func searchAction(_ sender: Any) {
        showAlertVC()
    }
    
    func searchPoetry(by type: Type, name: String!) {
        
        guard name.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            SVProgressHUD.showInfo(withStatus: "请输入有效字符")
            return
        }
        
        SVProgressHUD.show()
        dataSource.removeAll()
        let queue = DispatchQueue(label: "search")
        queue.async {
            PoetryManager.shareManager.dbQueue?.inTransaction({ (db, rollBack) in
                print(Thread.current.isMainThread)
                do {
                    let sql = """
                    SELECT *
                    FROM poem
                    WHERE \(type.rawValue) LIKE '%\(name!)%'
                    """
                    let result = try db.executeQuery(sql, values: [0])
                    
                    while result.next() {
                        let model = PoetryModel()
                        model.id = result.long(forColumn: "id")
                        model.author = result.string(forColumn: "author")!
                        model.title = result.string(forColumn: "title")!
                        model.txt = result.string(forColumn: "txt")!
                        self.dataSource.append(model)
                    }
                    
                    DispatchQueue.main.sync {
                        if self.dataSource.count == 0 {
                            SVProgressHUD.showInfo(withStatus: "该关键词没有搜索到相应诗词")
                            self.title = ""
                        } else {
                            SVProgressHUD.dismiss()
                        }
                        self.tableView.reloadData()
                    }
                } catch let error as NSError {
                    print("error:\(error)")
                }
            })
        }
//        PoetryManager.shareManager.dbQueue?.inDatabase({ (db) in
//            do {
//                let sql = """
//                SELECT *
//                FROM poem
//                WHERE \(type.rawValue) LIKE '%\(name!)%'
//                """
//                let result = try db.executeQuery(sql, values: [0])
//
//                while result.next() {
////                    print("\n\n")
////                    print(result.int(forColumn: "id"))
////                    print(result.string(forColumn: "title")!)
////                    print(result.string(forColumn: "author")!)
////                    print(result.string(forColumn: "txt")!)
//                    let model = PoetryModel()
//                    model.id = result.long(forColumn: "id")
//                    model.author = result.string(forColumn: "author")!
//                    model.title = result.string(forColumn: "title")!
//                    model.txt = result.string(forColumn: "txt")!
//                    self.dataSource.append(model)
//                }
//
//                if dataSource.count == 0 {
////                    let alertVC = UIAlertController(title: "该关键词没有搜索到相应诗词", message: name, preferredStyle: .alert)
////                    self.present(alertVC, animated: true, completion: {
////                        DispatchQueue.main.asyncAfter(deadline: .now()+1.0, execute: {
////                            alertVC.dismiss(animated: true, completion: {
////                            })
////                        })
////                    })
//                    SVProgressHUD.showInfo(withStatus: "该关键词没有搜索到相应诗词")
//                    self.title = ""
//                } else {
//                    SVProgressHUD.dismiss()
//                    self.tableView.reloadData()
//                }
//            } catch let error as NSError {
//                print("error:\(error)")
//            }
//        })
    }

}

extension ViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        guard reason == .committed && textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            return
        }
        keyword = (textField.text?.trimmingCharacters(in: .whitespacesAndNewlines))!
        title = "关键词：\(keyword)"
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        }
        cell?.textLabel?.text = dataSource[indexPath.row].title
        cell?.detailTextLabel?.text = dataSource[indexPath.row].author
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = dataSource[indexPath.row]
        let alertVC = UIAlertController(title: model.title, message: model.txt, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "ok", style: .cancel) { (_) in
        }
        alertVC.addAction(okAction)
        present(alertVC, animated: true, completion: nil)
    }
    
}

