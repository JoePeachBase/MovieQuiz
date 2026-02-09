import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    @IBOutlet private weak var questionLabel: UILabel!
    @IBOutlet private weak var questionCounterLabel: UILabel!
    @IBOutlet private weak var movieImageView: UIImageView!
    @IBOutlet private weak var questionTextLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private let presenter = MovieQuizPresenter()
    private var statisticService: StatisticServiceProtocol = StatisticService()
    private var correctAnswers = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var alertPresenter = AlertPresenter()
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setFonts()
        let questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        self.questionFactory = questionFactory
        statisticService = StatisticService()
        showLoadingIndicator()
        questionFactory.loadData()
        presenter.viewController = self
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        presenter.didReceiveNextQuestion(question: question)
    }
    
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        movieImageView.layer.masksToBounds = true
        movieImageView.layer.borderWidth = 8
        movieImageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        noButton.isEnabled.toggle()
        yesButton.isEnabled.toggle()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.noButton.isEnabled.toggle()
            self.yesButton.isEnabled.toggle()
            self.movieImageView.layer.borderWidth = 0
            self.presenter.correctAnswers = self.correctAnswers
            self.presenter.questionFactory = self.questionFactory
            self.presenter.showNextQuestionOrResults()
        }
    }
    
    func show(quiz step: QuizStepViewModel) {
        questionCounterLabel.text = step.questionNumber
        movieImageView.image = UIImage(data: step.image) ?? UIImage()
        questionTextLabel.text = step.question
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    
    // IB не видит шрифты, указал кодом
    private func setFonts() {
        questionLabel.font = UIFont(name: "YSDisplay-Medium", size: 20)
        questionCounterLabel.font = UIFont(name: "YSDisplay-Medium", size: 20)
        questionTextLabel.font = UIFont(name: "YSDisplay-Bold", size: 23)
        noButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
        yesButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
    }
    
    func show(quiz result: QuizResultsViewModel) {
        statisticService.store(correct: correctAnswers, total: presenter.questionsAmount)
        
        let bestGame = statisticService.bestGame
        let message =   """
                        Ваш результат: \(correctAnswers)/\(presenter.questionsAmount) 
                        Количество сыгранных квизов: \(statisticService.gamesCount)
                        Рекорд: \(bestGame.correct)/\(bestGame.total) (\(Date().dateTimeString))
                        Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
                        """
        
        let alertModel = AlertModel(
            title: result.title,
            message: message,
            buttonText: result.buttonText) { [weak self] in
                guard let self else { return }
                self.presenter.resetQuestionIndex()
                self.correctAnswers = 0
                self.questionFactory?.requestNextQuestion()
            }
        alertPresenter.show(in: self, model: alertModel)
    }
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let alertModel = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз") { [weak self] in
                guard let self else { return }
                
                self.presenter.resetQuestionIndex()
                self.correctAnswers = 0
                self.questionFactory?.requestNextQuestion()
            }
        alertPresenter.show(in: self, model: alertModel)
    }
}
