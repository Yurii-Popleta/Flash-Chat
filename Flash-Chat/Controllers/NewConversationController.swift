//
//  NewConversationController.swift
//  Flash-Chat
//
//  Created by Admin on 16/12/2022.
//

import UIKit
import JGProgressHUD

class NewConversationController: UIViewController {

    public var completion: (([String: String]) -> Void)?
    private let spinner = JGProgressHUD(style: .dark)
    private var allusers = [[String: String]]()
    private var resultsOfUsers = [[String: String]]()
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for users..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private let noResultsLable: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResultsLable)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = .white
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLable.frame = view.bounds
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true)
    }

}

extension NewConversationController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsOfUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = resultsOfUsers[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUser = resultsOfUsers[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.completion?(targetUser)
        }
    }
}

extension NewConversationController: UISearchBarDelegate  {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
         }
        searchBar.resignFirstResponder()
        resultsOfUsers.removeAll()
        spinner.show(in: view)
        searchingUsers(query: text)
    }
    
    func searchingUsers(query: String) {
        if hasFetched {
            filterUsers(with: query)
        } else {
            DatabaseManeger.share.getAllUsers { [weak self] results in
                switch results {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.allusers = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("failed to get users \(error)")
                    
                }
            }
        }
    }
    
    func filterUsers(with term: String) {
        guard hasFetched else {
            return
        }
        spinner.dismiss()
        var results: [[String: String]] = allusers.filter { result in
            guard let name = result["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }
        resultsOfUsers = results
        updateUI()
    }
    
    func updateUI() {
        if resultsOfUsers.isEmpty {
            noResultsLable.isHidden = false
            tableView.isHidden = true
        } else {
            noResultsLable.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
}
