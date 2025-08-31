//
//  ViewController.swift
//  MovieApp
//
//  Created by Sayed on 21/08/25.
//

import UIKit
import CoreData

class HomeViewController: UIViewController {
    @IBOutlet public var movieScrollView: UIScrollView?
    @IBOutlet public var backgroundView: UIView?
    @IBOutlet public var searchLabel: UILabel?
    @IBOutlet public var hintLabel: UILabel?
    @IBOutlet public var separatorLine: UIView?
    @IBOutlet public var searchView: UIView?
    var hintArray: [String] = ["Movie, Actors, Directors...", "Genres, Release year, Ratings...", "Action, Comedy, Drama, Sci-Fi...", "Upcoming, Now playing, Trending..."]
    var timer: Timer?
    var trendingtimer: Timer?
    var currentIndex: Int = 0
    @IBOutlet public var trendingLabel: UILabel?
    @IBOutlet public var trendingMoviesCollectionView: UICollectionView?
    @IBOutlet public var nowPlayingLabel: UILabel?
    @IBOutlet public var nowPlayingCollectionView: UICollectionView?
    @IBOutlet public var tabBarView: UIView?
    
    @IBOutlet public var homeView: UIView?
    @IBOutlet public var homeIcon: UIImageView?
    
    @IBOutlet public var searchTabView: UIView?
    
    @IBOutlet public var searchIcon: UIImageView?
    
    @IBOutlet public var saveView: UIView?
    
    @IBOutlet public var saveIcon: UIImageView?
    
    @IBOutlet public var scrollHeightConstraint: NSLayoutConstraint?
    var screeHeightY: CGFloat = UIScreen.main.bounds.height
    var isMovieScrollEnabled: Bool = true
    private var currentVC: UIViewController?
    private var trendingMovieViewModel: TrendingMoviesViewModel?
    private var nowPlayingViewModel: TrendingMoviesViewModel?
    private var bookmarkedListViewModel: BookmarkedListViewModel?
   
    var allTrendingMovies: [MovieDataUIModel]?
    var nowPlayingMovies: [MovieDataUIModel]?
    var bookmarkedMovies: [MovieItemDataUIModel]?
    let group = DispatchGroup()
    
    var isNowPlayPaginationEnabled: Bool = false
    var nowPlayPageNo: Int = 1
    var isTrendingPaginationEnabled: Bool = false
    var trendingPageNo: Int = 1
    var isTrendingDragged: Bool = false
    private var debouncePendingApiCall: DispatchWorkItem?
    private let refreshControl = UIRefreshControl()
    enum TabItems { case home, search, save }
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        bookmarkedListViewModel = BookmarkedListViewModel(delegate: self)
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.bookmarkedListViewModel?.fetchBookmarkedList(endpoint: "/list/8553900")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        callTrendingMovieAPI()
        setupNavigationBar()
        setupUI()
        setupCollectionView()
        setupTabBarView()
        setupRefreshControl()
    }
    private func setupRefreshControl() {
        refreshControl.tintColor = .white
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching movies...")
        movieScrollView?.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshMovies), for: .valueChanged)
    }
    
    @objc private func refreshMovies() {
        nowPlayPageNo = 1
        isTrendingDragged = false
        isNowPlayPaginationEnabled = false
        trendingPageNo = 1
        isTrendingPaginationEnabled = false
        callTrendingMovieAPI()
        DispatchQueue.main.async {
            self.scrollHeightConstraint?.constant = 20 * 160
        }
    }
    func callTrendingMovieAPI() {
        Utility.showLoader(on: self.view)
        trendingMovieViewModel = TrendingMoviesViewModel(delegate: self, component: self, category: .trending)
        nowPlayingViewModel = TrendingMoviesViewModel(delegate: self, component: self, category: .nowPlaying)
        
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.trendingMovieViewModel?.fetchTrendingMovies(endpoint: "/trending/movie/day")
        }
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.nowPlayingViewModel?.fetchTrendingMovies(endpoint: "/movie/now_playing")
        }
        
        group.notify(queue: .main) {
            self.trendingMoviesCollectionView?.reloadData()
            self.nowPlayingCollectionView?.reloadData()
            self.timer?.invalidate()
            self.trendingtimer?.invalidate()
            self.timer = nil
            self.trendingtimer = nil
            Utility.hideLoader()
            self.startAnimationTimer()
            self.showToast(message: "Movies loaded successfully")
            self.refreshControl.endRefreshing()
            self.scrollHeightConstraint?.constant = CGFloat((self.nowPlayingMovies?.count ?? 20) * 160)
        }
    }
    func setupNavigationBar() {
        navigationController?.navigationBar.isHidden = true
    }
    func setupUI() {
        movieScrollView?.bounces = true
        movieScrollView?.showsVerticalScrollIndicator = false
        movieScrollView?.delegate = self
        scrollHeightConstraint?.constant = (UIScreen.main.bounds.height * 1.5)
        view.backgroundColor = UIColor(red: 30/255.0, green: 30/255.0, blue: 41/255.0, alpha: 1.0)
        backgroundView?.backgroundColor = UIColor(red: 30/255.0, green: 30/255.0, blue: 41/255.0, alpha: 1.0)
        trendingMoviesCollectionView?.backgroundColor = UIColor(red: 30/255.0, green: 30/255.0, blue: 41/255.0, alpha: 1.0)
        nowPlayingCollectionView?.backgroundColor = UIColor(red: 30/255.0, green: 30/255.0, blue: 41/255.0, alpha: 1.0)
        searchView?.backgroundColor = UIColor(red: 30/255.0, green: 30/255.0, blue: 41/255.0, alpha: 1.0)
        let searchTapGesture = UITapGestureRecognizer(target: self, action: #selector(searchTapped))
        searchLabel?.text = "Search"
        searchLabel?.textColor = UIColor.gray
        searchLabel?.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        hintLabel?.text = "Movie, Actors, Directors..."
        hintLabel?.isUserInteractionEnabled = true
        hintLabel?.textColor = UIColor.gray
        hintLabel?.font = UIFont.systemFont(ofSize: 21, weight: .light)
        hintLabel?.addGestureRecognizer(searchTapGesture)
        separatorLine?.backgroundColor = UIColor.gray
        
        trendingLabel?.text = "Trending Movies"
        trendingLabel?.textColor = UIColor.white
        trendingLabel?.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        
        nowPlayingLabel?.text = "Now Playing"
        nowPlayingLabel?.textColor = UIColor.white
        nowPlayingLabel?.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
    }
    func startAnimationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: true, block: { [weak self] _ in
            self?.updateHintLabel()
        })
        trendingtimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(scrollToNextItem), userInfo: nil, repeats: true)
    }
    @objc func scrollToNextItem() {
        let itemCount = collectionView(trendingMoviesCollectionView ?? UICollectionView(), numberOfItemsInSection: 0)
        if itemCount == 0 { return }
        currentIndex = (currentIndex + 1) % itemCount
        let indexPath = IndexPath(item: currentIndex, section: 0)
        trendingMoviesCollectionView?.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    func updateHintLabel() {
        UIView.transition(with: hintLabel ?? UILabel(), duration: 0.5, options: .transitionFlipFromTop, animations: {
            self.hintLabel?.text = self.hintArray.randomElement()
        }, completion: nil)
    }
    func stopAutoScroll() {
        trendingtimer?.invalidate()
        trendingtimer = nil
    }
    func setupCollectionView() {
        trendingMoviesCollectionView?.delegate = self
        trendingMoviesCollectionView?.dataSource = self
        trendingMoviesCollectionView?.tag = 0
        let nib = UINib(nibName: "TrendingMovieCell", bundle: nil)
        trendingMoviesCollectionView?.register(nib, forCellWithReuseIdentifier: "TrendingMovieCell")
        trendingMoviesCollectionView?.showsHorizontalScrollIndicator = false
        if let layout = trendingMoviesCollectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        nowPlayingCollectionView?.delegate = self
        nowPlayingCollectionView?.dataSource = self
        nowPlayingCollectionView?.tag = 1
        nowPlayingCollectionView?.register(nib, forCellWithReuseIdentifier: "TrendingMovieCell")
        nowPlayingCollectionView?.showsVerticalScrollIndicator = false
        nowPlayingCollectionView?.bounces = false
        nowPlayingCollectionView?.isScrollEnabled = false
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == trendingMoviesCollectionView {
            stopAutoScroll()
        }
      }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == movieScrollView {
            
            let offsetY = scrollView.contentOffset.y
            let contentHeight = scrollView.contentSize.height
            let frameHeight = scrollView.frame.size.height
            if offsetY + frameHeight >= contentHeight {
                debouncePendingApiCall?.cancel()
                isNowPlayPaginationEnabled = true
                
                isTrendingDragged = false
                Utility.showLoader(on: self.view)
                let requestWorkItem = DispatchWorkItem { [weak self] in
                    self?.nowPlayPageNo  += 1
                    self?.loadMorePages()
                }
                debouncePendingApiCall = requestWorkItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: requestWorkItem)
                
            }
        }
    }
    
    func loadMorePages() {
        DispatchQueue.global(qos: .userInitiated).async  { [weak self] in
            self?.nowPlayingViewModel?.fetchTrendingMovies(endpoint: "/movie/now_playing")
        }
    }
    

}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let trendingCount = allTrendingMovies?.count ?? 0
        let nowPlayingCount = nowPlayingMovies?.count ?? 0

        guard trendingCount > 0 else { return 0 }
        guard nowPlayingCount > 0 else { return 0 }
        
        return collectionView.tag == 0 ? trendingCount : nowPlayingCount
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendingMovieCell", for: indexPath) as! TrendingMovieCell
        cell.movieImageView?.image = nil

        if collectionView.tag == 0 {
            // Trending Movies
            guard let trendingMovies = allTrendingMovies, indexPath.row < trendingMovies.count else { return cell }
            let movie = trendingMovies[indexPath.row]

            let genreNames = Utility.getGenreNames(for: movie.genreIds).joined(separator: ", ")
            let posterURL = URL(string: "https://image.tmdb.org/t/p/w500\(movie.posterPath)")

            if let savedImage = MoviePersistenceManager.shared.getPosterImage(movieId: movie.id) {
                cell.movieImageView?.image = savedImage
            } else {
                cell.movieImageView?.loadImage(from: posterURL)
            }

            cell.movieTitleLabel?.text = movie.title
            cell.movieSubtitle?.text = genreNames
            cell.imgLeadingConstraint?.constant = 20
            cell.imgTrailingConstraint?.constant = 10
        } else {
            // Now Playing
            guard let nowPlayingMovies = nowPlayingMovies, indexPath.row < nowPlayingMovies.count else { return cell }
            let movie = nowPlayingMovies[indexPath.row]

            let genreNames = Utility.getGenreNames(for: movie.genreIds).joined(separator: ", ")
            let posterURL = URL(string: "https://image.tmdb.org/t/p/w500\(movie.posterPath)")

            if let savedImage = MoviePersistenceManager.shared.getPosterImage(movieId: movie.id) {
                cell.movieImageView?.image = savedImage
            } else {
                cell.movieImageView?.loadImage(from: posterURL)
            }

            cell.movieTitleLabel?.text = movie.title
            cell.movieSubtitle?.text = genreNames
            cell.imgLeadingConstraint?.constant = 0
            cell.imgTrailingConstraint?.constant = 0
        }

        return cell
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView.tag == 0 {
            let lastItem = collectionView.numberOfItems(inSection: indexPath.section) - 1
            if indexPath.item == lastItem &&
                (collectionView.isDragging || collectionView.isDecelerating) {
                isTrendingPaginationEnabled = true
                isTrendingDragged = true
                trendingPageNo  += 1
                Utility.showLoader(on: self.view)
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.trendingMovieViewModel?.fetchTrendingMovies(endpoint: "/trending/movie/day")
                }
            }
        } 
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let deviceWidth = UIScreen.main.bounds.width
        let cellWidth: CGFloat = deviceWidth * 0.40
        let trendingSize: CGSize = CGSize(width: 320, height: 280)
        let nowPlayingSize: CGSize = CGSize(width: cellWidth, height: 260)
        
        return collectionView.tag == 0 ? trendingSize : nowPlayingSize
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var selectedMovieID: Int? = -1
        if collectionView.tag == 0 {
            selectedMovieID =  allTrendingMovies?[indexPath.row].id
        } else {
            selectedMovieID =  nowPlayingMovies?[indexPath.row].id
        }
        
        let vc = MovieDetailsViewController(nibName: "MovieDetailsViewController", bundle: nil)
        vc.selectedMovieId = selectedMovieID
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension HomeViewController {
    func setupTabBarView() {
        homeView?.backgroundColor = .clear
        searchTabView?.backgroundColor = .clear
        saveView?.backgroundColor = .clear
        tabBarView?.backgroundColor = UIColor(red: 36/255.0, green: 34/255.0, blue: 58/255.0, alpha: 1.0)
        tabBarView?.alpha = 0.95
        homeIcon?.image = UIImage(named: "home_icon_clicked")?.withTintColor(UIColor.white)
        searchIcon?.image = UIImage(named: "search_icon_uncliked")?.withTintColor(UIColor.white)
        saveIcon?.image = UIImage(named: "save_icon_unclicked")?.withTintColor(UIColor.white)
        addTapGestures()
    }
    func addTapGestures() {
        let homeTapGesture = UITapGestureRecognizer(target: self, action: #selector(homeTapped))
        homeView?.addGestureRecognizer(homeTapGesture)
        let searchTapGesture = UITapGestureRecognizer(target: self, action: #selector(searchTapped))
        searchTabView?.addGestureRecognizer(searchTapGesture)
        let saveTapGesture = UITapGestureRecognizer(target: self, action: #selector(saveTapped))
        saveView?.addGestureRecognizer(saveTapGesture)
    }
    @objc func homeTapped() {
        switchToTab(.home)
    }
    @objc func searchTapped() {
        switchToTab(.search)
    }
    @objc func saveTapped() {
        switchToTab(.save)
    }
    private func switchToTab(_ tab: TabItems) {
        homeIcon?.image = UIImage(named: "home_icon_unclicked")?.withTintColor(.white)
        searchIcon?.image = UIImage(named: "search_icon_uncliked")?.withTintColor(.white)
        saveIcon?.image = UIImage(named: "save_icon_unclicked")?.withTintColor(.white)
        if let current = currentVC,
           !(current is HomeViewController) {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        var newVC: UIViewController?

        switch tab {
        case .home:
            movieScrollView?.isScrollEnabled = true
            movieScrollView?.setContentOffset(.zero, animated: false)
            homeIcon?.image = UIImage(named: "home_icon_clicked")?.withTintColor(.white)
            currentVC = nil

        case .search:
            let searchVC = SearchViewController()
            searchVC.bookmarkedMovies = bookmarkedMovies
            newVC = searchVC
            movieScrollView?.isScrollEnabled = false
            movieScrollView?.setContentOffset(.zero, animated: false)
            searchIcon?.image = UIImage(named: "search_icon_cliked")?.withTintColor(.white)

        case .save:
            let savedVC = SavedMoviesViewController()
            savedVC.bookmarkedMovie = bookmarkedMovies
            newVC = savedVC
            movieScrollView?.setContentOffset(.zero, animated: false)
            movieScrollView?.isScrollEnabled = false
            saveIcon?.image = UIImage(named: "save_icon_clicked")?.withTintColor(.white)
        }
        if let newVC = newVC {
            addChild(newVC)
            newVC.view.frame = backgroundView?.bounds ?? .zero
            backgroundView?.addSubview(newVC.view)
            newVC.didMove(toParent: self)
            currentVC = newVC
        }
    }


}

extension HomeViewController: TrendingMoviesDependency, TrendingMoviesFlowDelegate, BookmarkedListFlowDelegate {
    func getPageNo() -> Int? {
        return isTrendingDragged ? trendingPageNo : nowPlayPageNo
    }
    
    func actionBookmarkedListSuccessful(data: BookmarkedListDataUIModel) {
        bookmarkedMovies = data.items
        var posters: [Int: UIImage] = [:]
        let innerGroup = DispatchGroup()
        
        for movie in data.items {
            innerGroup.enter()
            let url = URL(string: "https://image.tmdb.org/t/p/w500\(movie.posterPath)")!
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    posters[movie.id] = image
                }
                innerGroup.leave()
            }.resume()
        }
        innerGroup.notify(queue: .main) {
            
            let savedMovies = data.items.map { obj in
                MovieDataUIModel(id: obj.id, title: obj.title, overview: obj.title, posterPath: obj.posterPath, releaseDate: "", voteAverage: 0.0, originalLanguage: "", genreIds: obj.genreIds)
            }
            MoviePersistenceManager.shared.saveMovies(savedMovies,
                                                      posterImages: posters,
                                                      category: .savedMovies)

        }
        group.leave()
    }
    
    func actionBookmarkedListFailed(error: BookmarkedListErrorUIModel) {
        if error.statusCode == "NO_INTERNET" {
            DispatchQueue.main.async { [weak self] in
                self?.showToast(message: "No Internet Connection")
            }
        }
        let savedMovies = MoviePersistenceManager.shared.fetchMovies(for: .savedMovies)
        bookmarkedMovies = savedMovies.map({ obj in
            MovieItemDataUIModel(title: obj.title, posterPath: obj.posterPath, genreIds: obj.genreIds, id: obj.id)
        })
        group.leave()
    }
    
    func actionFetchTrendingMoviesSuccessful(data: TrendingMoviesDataUIModel, for category: MovieCategory) {
        switch category {
        case .trending:
            MoviePersistenceManager.shared.clearCoreData()
            MoviePersistenceManager.shared.clearDiskImages()
            MoviePersistenceManager.shared.clearMemoryCache()
            if isTrendingPaginationEnabled {
                allTrendingMovies?.append(contentsOf: data.results)
                DispatchQueue.main.async { [weak self] in
                    Utility.hideLoader()
                    self?.trendingMoviesCollectionView?.reloadData()
                    
                }
            } else {
                allTrendingMovies = []
                allTrendingMovies = data.results
                var posters: [Int: UIImage] = [:]
                let innerGroup = DispatchGroup()
                
                for movie in data.results {
                    innerGroup.enter()
                    let url = URL(string: "https://image.tmdb.org/t/p/w500\(movie.posterPath)")!
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data, let image = UIImage(data: data) {
                            posters[movie.id] = image
                        }
                        innerGroup.leave()
                    }.resume()
                }
                
                innerGroup.notify(queue: .main) {
                    MoviePersistenceManager.shared.saveMovies(data.results,
                                                              posterImages: posters,
                                                              category: .trending)
                    
                }
                group.leave()
            }
        case .nowPlaying:
            if isNowPlayPaginationEnabled {
                nowPlayingMovies?.append(contentsOf: data.results)
                DispatchQueue.main.async { [weak self] in
                    Utility.hideLoader()
                    self?.nowPlayingCollectionView?.reloadData()
                    self?.scrollHeightConstraint?.constant += CGFloat(20 * 130)
                }
            } else {
                nowPlayingMovies = []
                nowPlayingMovies = data.results
                
                var posters: [Int: UIImage] = [:]
                let innerGroup = DispatchGroup()
                
                for movie in data.results {
                    innerGroup.enter()
                    let url = URL(string: "https://image.tmdb.org/t/p/w500\(movie.posterPath)")!
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data, let image = UIImage(data: data) {
                            posters[movie.id] = image
                        }
                        innerGroup.leave()
                    }.resume()
                }
                
                innerGroup.notify(queue: .main) {
                    MoviePersistenceManager.shared.saveMovies(data.results,
                                                              posterImages: posters,
                                                              category: .nowPlaying)
                    
                }
                group.leave()
            }
        case .savedMovies:
            debugPrint("Saved movies - should not be here")
        }
    }
    
    func actionFetchTrendingMoviesFailed(error: TrendingMoviesErrorUIModel, for category: MovieCategory) {
        dump(error)
        if error.statusCode == "NO_INTERNET" {
            DispatchQueue.main.async { [weak self] in
                self?.showToast(message: "No Internet Connection")
            }
        }
        allTrendingMovies = []
        nowPlayingMovies = []
        allTrendingMovies = MoviePersistenceManager.shared.fetchMovies(for: .trending)
        nowPlayingMovies = MoviePersistenceManager.shared.fetchMovies(for: .nowPlaying)
        DispatchQueue.main.async { [weak self] in
            self?.movieScrollView?.setContentOffset(.zero, animated: false)
            self?.refreshControl.endRefreshing()
            self?.trendingMoviesCollectionView?.reloadData()
            self?.nowPlayingCollectionView?.reloadData()
        }
        
        if isTrendingPaginationEnabled || isNowPlayPaginationEnabled {
            DispatchQueue.main.async { [weak self] in
                Utility.hideLoader()
                self?.showToast(message: "Unable to load new movies")
            }
        } else {
            group.leave()
        }
       
    }
    
    func getLanguageCode() -> String? {
        return "en-US"
    }
}

