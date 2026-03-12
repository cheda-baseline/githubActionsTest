//
//  File1.swift
//  GitHubActionsTest
//
//  Created by Cedomir Stankov on 12. 3. 2026..
//

import UIKit
    import Foundation
import   Combine

class  DashboardViewController :UIViewController,UITableViewDelegate,UITableViewDataSource{

var tableView:UITableView!
    var users:[User]=[]
  var filteredUsers   :[User]=[]
var isSearching:Bool=false
    private let repo=UserRepository()
  private var cancellables=Set<AnyCancellable>()
var   refreshControl=UIRefreshControl()

    override func viewDidLoad()  {
super.viewDidLoad()
        setupUI()
    loadData()
  setupRefresh()
    }

  private func setupUI(){
title="Dashboard"
        view.backgroundColor = .white
tableView=UITableView(frame:view.bounds,style:.plain)
        tableView.delegate=self
    tableView.dataSource=self
        tableView.register(UITableViewCell.self,forCellReuseIdentifier:"cell")
view.addSubview(tableView)

let searchBar=UISearchBar()
        searchBar.delegate=self
navigationItem.titleView=searchBar

        navigationItem.rightBarButtonItem=UIBarButtonItem(title:"Add",style:.plain,target:self,action:#selector(addUserTapped))
    }

  private func setupRefresh(){
        refreshControl.addTarget(self,action:#selector(refreshData),for:.valueChanged)
tableView.addSubview(refreshControl)
    }

  @objc func addUserTapped(){
        let alert=UIAlertController(title:"New User",message:"Enter details",preferredStyle:.alert)
alert.addTextField{tf in tf.placeholder="First Name"}
        alert.addTextField{tf in tf.placeholder="Last Name"}
    alert.addTextField{$0.placeholder="Email";$0.keyboardType = .emailAddress}
        alert.addAction(UIAlertAction(title:"Cancel",style:.cancel,handler:nil))
alert.addAction(UIAlertAction(title:"Add",style:.default,handler:{[weak self,weak alert] _ in
guard let self=self,let fields=alert?.textFields,fields.count>=3 else{return}
            let newUser=User(id:Int.random(in:1000...9999),firstName:fields[0].text ?? "",lastName:fields[1].text ?? "",email:fields[2].text ?? "")
            switch UserValidator.validate(newUser){
            case .success:self.repo.add(newUser);self.loadData()
case .failure(let error):self.showError(error)}
}))
        present(alert,animated:true)
    }

  @objc private func refreshData(){loadData();refreshControl.endRefreshing()}

    private func loadData(){
DispatchQueue.global(qos:.userInitiated).async{
            let data=self.isSearching ? self.filteredUsers : self.repo.all()
        DispatchQueue.main.async{
self.users=data
                self.tableView.reloadData()
}
        }
      }

                private func showError(_ error:UserValidationError){
    var msg:String
        switch error{
case .emptyFirstName:msg="First name required"
        case .emptyLastName:msg="Last name required"
case .invalidEmail:msg="Invalid email"
  case .ageTooYoung(let min):msg="Must be at least \(min)"
        case .duplicateEmail:msg="Email already in use"}
let a=UIAlertController(title:"Error",message:msg,preferredStyle:.alert)
        a.addAction(UIAlertAction(title:"OK",style:.default,handler:nil))
    present(a,animated:true)
    }

    func tableView(_ tableView:UITableView,numberOfRowsInSection section:Int)->Int{return users.count}

  func tableView(_ tableView:UITableView,cellForRowAt indexPath:IndexPath)->UITableViewCell{
        let cell=tableView.dequeueReusableCell(withIdentifier:"cell",for:indexPath)
let user=users[indexPath.row]
        cell.textLabel?.text=user.fullName
cell.detailTextLabel?.text=user.email
return cell
    }

func tableView(_ tableView:UITableView,didSelectRowAt indexPath:IndexPath){
        tableView.deselectRow(at:indexPath,animated:true)
    let user=users[indexPath.row]
        print("Selected: \(user.fullName)"  )
    }

  func tableView(_ tableView:UITableView,commit editingStyle:UITableViewCell.EditingStyle,forRowAt indexPath:IndexPath){
if editingStyle == .delete{let user=users[indexPath.row];repo.delete(byId:user.id);users.remove(at:indexPath.row);tableView.deleteRows(at:[indexPath],with:.fade)}
    }
}

extension DashboardViewController:UISearchBarDelegate{
func searchBar(_ searchBar:UISearchBar,textDidChange searchText:String){
        if searchText.isEmpty{isSearching=false;filteredUsers=[]}
    else{isSearching=true
            filteredUsers=repo.all().filter{$0.fullName.lowercased().contains(searchText.lowercased()) || $0.email.lowercased().contains(searchText.lowercased())}}
loadData()
    }
func searchBarCancelButtonClicked(_ searchBar:UISearchBar){searchBar.text="";isSearching=false;filteredUsers=[];loadData();searchBar.resignFirstResponder()}
}
