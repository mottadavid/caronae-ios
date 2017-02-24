import UIKit

class AllRidesViewController: RideListController, SearchRideDelegate {
    var searchParams: [String: Any] = [:]
    fileprivate var nextPage = 2

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.view.backgroundColor = UIColor.white
        navigationItem.titleView = UIImageView(image: UIImage(named: "NavigationBarLogo"))
        
        // Setting up infinite scroll
        tableView.infiniteScrollIndicatorMargin = 40
        tableView.infiniteScrollTriggerOffset = 500
        
        tableView.addInfiniteScroll { (tableView) -> Void in
            self.loadAllRides(page: self.nextPage)
            tableView.finishInfiniteScroll()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadAllRides()
    }
    
    func refreshTable() {
        self.loadAllRides()
    }
    
    
    // MARK: Table methods
    
    lazy var tableFooter: UIView = {
        let tableFooter = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
        tableFooter.text = "Quer encontrar mais caronas? Use a pesquisa! 🔍"
        tableFooter.numberOfLines = 0
        tableFooter.backgroundColor = .white
        tableFooter.font = .systemFont(ofSize: 10)
        tableFooter.textColor = .lightGray
        tableFooter.textAlignment = .center
        return tableFooter
    }()
    
    
    // MARK: Rides methods
    
    func loadAllRides(page: Int = 1) {
        if self.tableView.backgroundView != nil {
            self.tableView.backgroundView = self.loadingLabel;
        }
        
        RideService.instance.getAllRides(page: page, success: { rides in
            
            if page == 1 {
                self.nextPage = 2
                self.rides = rides
            } else {
                self.nextPage += 1
                var allRides = self.rides as! [Ride]
                allRides.append(contentsOf: rides)
                self.rides = allRides
            }
            
            self.tableView.reloadData()
            
            if rides.count > 0 {
                self.tableView.tableFooterView = self.tableFooter
            } else {
                self.tableView.tableFooterView = nil
            }
            
            self.refreshControl.endRefreshing()
        }, error: { error in
            self.refreshControl.endRefreshing()
            self.loadingFailedWithError(error)
        })
    }
    
    
    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SearchRide" {
            if let searchNavController = segue.destination as? UINavigationController {
                let searchVC = searchNavController.viewControllers.first as! SearchRideViewController
                searchVC.previouslySelectedSegmentIndex = self.directionControl.selectedSegmentIndex
                searchVC.delegate = self
            }
        } else if segue.identifier == "ViewSearchResults" {
            if let searchViewController = segue.destination as? SearchResultsViewController {
                searchViewController.searchedForRide(withCenter: self.searchParams["center"] as! String!,
                                                     andNeighborhoods: self.searchParams["neighborhoods"] as! [Any]!,
                                                     on: self.searchParams["date"] as! Date!,
                                                     going: self.searchParams["going"] as! Bool)
            }
        }
    }
    
    
    // MARK: Search methods
    
    func searchedForRide(withCenter center: String, andNeighborhoods neighborhoods: [Any], on date: Date, going: Bool) {
    self.searchParams = ["center": center,
        "neighborhoods": neighborhoods,
        "date": date,
        "going": going
    ]
    
    self.performSegue(withIdentifier: "ViewSearchResults", sender: self)
    }

}
