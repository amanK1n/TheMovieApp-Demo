//
//  MovieDetailsViewController.swift
//  MovieApp
//
//  Created by Sayed on 23/08/25.
//

import UIKit
import MarqueeLabel

class MovieDetailsViewController: UIViewController {
    @IBOutlet public var backImageIcon: UIImageView?
    @IBOutlet public var detailImage: UIImageView?
    @IBOutlet public var shareImgView: UIImageView?
    private var movieDetailsViewModel: MovieDetailsViewModel?
    @IBOutlet public var detailsImageHeight: NSLayoutConstraint?
    private var movieDetailsDataUIModel: MovieDetailsDataUIModel?
     var selectedMovieObj: MovieDetailsDataUIModel?
    private var addRemoveMovieViewModel: AddMovieViewModel?
    let screenHeight: CGFloat = UIScreen.main.bounds.height
    @IBOutlet public var movieTitleLang: MarqueeLabel?
    @IBOutlet public var yearLabel: UILabel?
    @IBOutlet public var detailStackView: UIStackView?
    @IBOutlet public var genreView: UIView?
    @IBOutlet public var durationView: UIView?
    @IBOutlet public var ratingsView: UIView?
    @IBOutlet public var genreImgView: UIImageView?
    @IBOutlet public var genreLabel: MarqueeLabel?
    @IBOutlet public var genreSeparator: UIView?
    @IBOutlet public var durationImgView: UIImageView?
    @IBOutlet public var durationLabel: UILabel?
    @IBOutlet public var durationSeparator: UIView?
    @IBOutlet public var ratingImgView: UIImageView?
    @IBOutlet public var ratingLabel: UILabel?
    @IBOutlet public var ratingSeparator: UIView?
    @IBOutlet public var bookmarkMovie: UIButton?
    @IBOutlet public var overviewTextView: UITextView?
     var selectedMovieId: Int?
    var isBookmarked: Bool = false
    var allOfflinedMovies: [MovieDataUIModel]?
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let posterImageView = detailImage {
            addGradientToImageView(posterImageView)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchSelectedMovie()
        setupUI()
        Utility.showLoader(on: self.view)
        callMovieDetailAPI()
        fetchSelectedMovie()
    }
    
    func fetchSelectedMovie() {
        let trendingMovies = MoviePersistenceManager.shared.fetchMovies(for: .trending)
        let nowPlayingMovies = MoviePersistenceManager.shared.fetchMovies(for: .nowPlaying)
        allOfflinedMovies = trendingMovies + nowPlayingMovies
        self.isBookmarked = MoviePersistenceManager.shared.fetchMovies(for: .savedMovies).contains(where: { obj in
            obj.id == selectedMovieId
        })
        
        
        
        selectedMovieObj = allOfflinedMovies?.first(where: { $0.id == selectedMovieId })
            .map {
                let genre = $0.genreIds.map { obj in
                    GenreDataUIModel(id: obj, name: Utility.getGenreNames(for: [obj]).first ?? "" )
                }
                return MovieDetailsDataUIModel(id: $0.id, title: $0.title, genres: genre, originalLanguage: $0.originalLanguage ?? "NA", originalTitle: $0.title, overview: $0.overview, posterPath: $0.posterPath, releaseDate: $0.releaseDate ?? "NA", runtime: 0, rating: String(format: "%.1f", $0.voteAverage ?? 0)  , tagline: "")
            }
    }
    
    func callMovieDetailAPI() {
        movieDetailsViewModel = MovieDetailsViewModel(delegate: self, component: self)
        addRemoveMovieViewModel = AddMovieViewModel(delegate: self, component: self)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.movieDetailsViewModel?.fetchTrendingMovies(endpoint: "/movie/")
            
        }
    }
    
    func setupBackImage() {
        let backImage = UIImage(named: "right-arrow")?.withHorizontallyFlippedOrientation().withTintColor(.white)
        backImageIcon?.image = backImage
        backImageIcon?.backgroundColor = .lightGray
        backImageIcon?.layer.cornerRadius = 15.0
        backImageIcon?.layer.masksToBounds = true
        backImageIcon?.clipsToBounds = true
        backImageIcon?.contentMode = .scaleAspectFit
        backImageIcon?.isUserInteractionEnabled = true
        backImageIcon?.alpha = 0.7
        let inset: CGFloat = 2
        let paddedImage = backImage?.withAlignmentRectInsets(
            UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        )
        backImageIcon?.image = paddedImage
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backButtonTapped))
        backImageIcon?.addGestureRecognizer(tapGesture)
    }
    func setupShareImg() {
        shareImgView?.image = UIImage(systemName: "square.and.arrow.up")
        shareImgView?.tintColor = .white
        shareImgView?.backgroundColor = .lightGray
        shareImgView?.layer.cornerRadius = 15.0
        shareImgView?.layer.masksToBounds = true
        shareImgView?.clipsToBounds = true
        shareImgView?.contentMode = .scaleAspectFit
        shareImgView?.isUserInteractionEnabled = true
        shareImgView?.alpha = 0.7
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(shareButtonTapped))
        shareImgView?.addGestureRecognizer(tapGesture)
    }
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    @objc func shareButtonTapped() {
        let movieId = movieDetailsDataUIModel?.id ?? -1
        shareMovie(movieId: movieId)
    }
    func generateMovieDeepLink(movieId: Int) -> URL? {
        let urlString = "myapp://movie/\(movieId)"
        return URL(string: urlString)
    }
    func shareMovie(movieId: Int) {
        guard let url = generateMovieDeepLink(movieId: movieId) else { return }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
    }

    
    @IBAction func bookmarkBtnAction(_ sender: Any) {
        Utility.showLoader(on: self.view)
        if isBookmarked {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.addRemoveMovieViewModel?.addMovie(endpoint: "/list/8553900/remove_item")
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.addRemoveMovieViewModel?.addMovie(endpoint: "/list/8553900/add_item")
            }
        }
    }
    
    func setupUI() {
        detailsImageHeight?.constant = CGFloat(screenHeight * 0.5)
        view.backgroundColor = UIColor(red: 19/255.0, green: 8/255.0, blue: 24/255.0, alpha: 1.0)
        overviewTextView?.textColor = .white
        overviewTextView?.backgroundColor = UIColor(red: 19/255.0, green: 8/255.0, blue: 24/255.0, alpha: 1.0)
        detailStackView?.backgroundColor = UIColor(red: 19/255.0, green: 8/255.0, blue: 24/255.0, alpha: 1.0)
        genreView?.backgroundColor = UIColor(red: 19/255.0, green: 8/255.0, blue: 24/255.0, alpha: 1.0)
        durationView?.backgroundColor = UIColor(red: 19/255.0, green: 8/255.0, blue: 24/255.0, alpha: 1.0)
        ratingsView?.backgroundColor = UIColor(red: 19/255.0, green: 8/255.0, blue: 24/255.0, alpha: 1.0)
        movieTitleLang?.type = .continuous
        movieTitleLang?.speed = .duration(5.0)
        movieTitleLang?.animationCurve = .easeInOut
        movieTitleLang?.fadeLength = 10.0
        movieTitleLang?.trailingBuffer = 20.0
        movieTitleLang?.leadingBuffer = 0.0
        
        genreLabel?.type = .continuous
        genreLabel?.speed = .duration(5.0)
        genreLabel?.animationCurve = .easeInOut
        genreLabel?.fadeLength = 10.0
        genreLabel?.trailingBuffer = 20.0
        genreLabel?.leadingBuffer = 0.0
        
        setupBackImage()
        setupShareImg()
        setupBookmarkButton()
    }
    func setupBookmarkButton() {
        if isBookmarked {
            bookmarkMovie?.setTitle("Bookmarked", for: .normal)
        } else {
            bookmarkMovie?.setTitle("Bookmark this movie", for: .normal)
        }
        bookmarkMovie?.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        bookmarkMovie?.setTitleColor(.white, for: .normal)
        bookmarkMovie?.backgroundColor = UIColor(red: 228/255.0, green: 1/255.0, blue: 2/255.0, alpha: 1.0)
        bookmarkMovie?.layer.cornerRadius = 8
    }
    func addGradientToImageView(_ imageView: UIImageView) {
        if let sublayers = imageView.layer.sublayers,
           sublayers.contains(where: { $0.name == "gradientLayer" }) {
            return
        }
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "gradientLayer"
        gradientLayer.frame = detailImage?.bounds ?? CGRect()
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor(red: 19/255.0, green: 8/255.0, blue: 24/255.0, alpha: 1.0).withAlphaComponent(1.0).cgColor
        ]
        gradientLayer.locations = [0.5, 1.0]
        detailImage?.layer.addSublayer(gradientLayer)
    }
}
extension MovieDetailsViewController: MovieDetailsDependency, MovieDetailsFlowDelegate {
    func getMovieID() -> Int? {
        return selectedMovieId
    }
    
    func actionMovieDetailsSuccessful(data: MovieDetailsDataUIModel) {
        movieDetailsDataUIModel = data
        DispatchQueue.main.async { [weak self] in
            self?.setupTitle()
            Utility.hideLoader()
        }
    }
    
    func actionMovieDetailsFailed(error: MovieDetailsErrorUIModel) {
        if error.statusCode == "NO_INTERNET" {
            DispatchQueue.main.async { [weak self] in
                self?.showToast(message: "No Internet Connection")
            }
        }
        movieDetailsDataUIModel = selectedMovieObj
        DispatchQueue.main.async { [weak self] in
            self?.setupTitle()
            Utility.hideLoader()
        }
        
    }
    
    func setupTitle() {
        let title = movieDetailsDataUIModel?.title ?? ""
        var lang = movieDetailsDataUIModel?.originalLanguage ?? ""
        lang = languageName(for: lang)
        let yearArr = movieDetailsDataUIModel?.releaseDate.split(separator: "-") ?? []
        let year = yearArr.first ?? ""
        movieTitleLang?.text = "\(title) : \(lang)"
        movieTitleLang?.textColor = .white
        movieTitleLang?.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        yearLabel?.text = String(year)
        yearLabel?.textColor = .white
        yearLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        setupDesc()
    }
    func languageName(for code: String) -> String {
        let locale = Locale.current
        return locale.localizedString(forLanguageCode: code) ?? code
    }
    func setupDesc() {
        genreImgView?.image = UIImage(systemName: "play.fill")
        genreImgView?.tintColor = .white
        
        
        genreLabel?.text = movieDetailsDataUIModel?.genres.map {
            $0.name
        }.joined(separator: ", ")
        genreLabel?.textColor = .white
        genreLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        durationImgView?.image = UIImage(systemName: "clock.fill")
        durationImgView?.tintColor = .white
        let runtime = movieDetailsDataUIModel?.runtime ?? 0
        let hour = (runtime / 60)
        let min = (runtime % 60)
        durationLabel?.text = "\(hour)h \(min)m"
        durationLabel?.textColor = .white
        durationLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        ratingImgView?.image = UIImage(systemName: "star.fill")
        ratingImgView?.tintColor = .white
        ratingLabel?.text = movieDetailsDataUIModel?.rating
        ratingLabel?.textColor = .white
        ratingLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        ratingSeparator?.isHidden = true
        setupOverview()
    }
    func setupOverview() {
        overviewTextView?.text = movieDetailsDataUIModel?.overview ?? ""
        overviewTextView?.isEditable = false
        overviewTextView?.isScrollEnabled = true
        overviewTextView?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        setupDetailImage()
    }
    func setupDetailImage() {
        let posterPath = movieDetailsDataUIModel?.posterPath ?? ""
        let posterFullPath = "https://image.tmdb.org/t/p/w500" + posterPath
        let posterURL = URL(string: posterFullPath)
        detailImage?.contentMode = .scaleAspectFill
        detailImage?.clipsToBounds = true
        if let savedImage = MoviePersistenceManager.shared.getPosterImage(movieId: movieDetailsDataUIModel?.id ?? -1) {
            detailImage?.image = savedImage
        } else {
            detailImage?.loadImage(from: posterURL)
        }
    }
}
extension MovieDetailsViewController: AddMovieDependency, AddMovieFlowDelegate {
    func getMovieId() -> Int? {
        return selectedMovieId
    }
    
    func actionAddMovieSuccessful(data: AddMovieDataUIModel) {
        Utility.hideLoader()
        if data.statusCode == 12 {
            isBookmarked = true
            DispatchQueue.main.async { [weak self] in
                self?.bookmarkMovie?.setTitle("Bookmarked", for: .normal)
            }
        } else {
            isBookmarked = false
            MoviePersistenceManager.shared.deleteMovie(byId: selectedMovieId ?? -1)
            DispatchQueue.main.async { [weak self] in
                self?.bookmarkMovie?.setTitle("Bookmark this movie", for: .normal)
            }
        }
    }
    
    func actionAddMovieFailed(error: AddMovieErrorUIModel) {
        Utility.hideLoader()
        if error.statusCode == "NO_INTERNET" {
            DispatchQueue.main.async { [weak self] in
                self?.showToast(message: "No Internet Connection")
            }
        } else {
            let msg = isBookmarked ? "Unable to remove movie" : "Unable to add movie"
            DispatchQueue.main.async { [weak self] in
                self?.showToast(message: msg)
            }
        }
    }
}
