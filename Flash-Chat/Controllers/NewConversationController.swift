
import UIKit
import JGProgressHUD

class NewConversationController: UIViewController {

    public var completion: ((SearchResult) -> Void)?
    private let spinner = JGProgressHUD(style: .dark)
    private var allusers = [[String: String]]()
    private var resultsOfUsers = [SearchResult]()
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for users..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
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
        view.backgroundColor = .systemBackground
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
        let model = resultsOfUsers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUser = resultsOfUsers[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.completion?(targetUser)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
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
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        
        spinner.dismiss()
        let results: [SearchResult] = allusers.filter { result in
            guard let email = result["email"], email != currentUserEmail else {
                return false
            }
            
            guard let name = result["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }.compactMap { result in
            guard let email = result["email"], let name = result["name"] else {
                return nil
            }
            
            return SearchResult(name: name, email: email)
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

struct SearchResult {
    let name: String
    let email: String
}
