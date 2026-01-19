import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    @IBOutlet private weak var questionLabel: UILabel!
    @IBOutlet private weak var questionCounterLabel: UILabel!
    @IBOutlet private weak var movieImageView: UIImageView!
    @IBOutlet private weak var questionTextLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    
    private let questionsAmount = 10
    private let statisticService: StatisticServiceProtocol = StatisticService()
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter = AlertPresenter()
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setFonts()
        let questionFactory = QuestionFactory()
        questionFactory.delegate = self
        self.questionFactory = questionFactory
        questionFactory.requestNextQuestion()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        currentQuestion = question
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion else { return }
        showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion else { return }
        showAnswerResult(isCorrect: currentQuestion.correctAnswer)
    }
    
    // IB не видит шрифты, указал кодом
    private func setFonts() {
        questionLabel.font = UIFont(name: "YSDisplay-Medium", size: 20)
        questionCounterLabel.font = UIFont(name: "YSDisplay-Medium", size: 20)
        questionTextLabel.font = UIFont(name: "YSDisplay-Bold", size: 23)
        noButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
        yesButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let quizStepViewModel = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return quizStepViewModel
    }
    
    private func show(quiz step: QuizStepViewModel) {
        questionCounterLabel.text = step.questionNumber
        movieImageView.image = step.image
        questionTextLabel.text = step.question
    }
    
    private func showAnswerResult(isCorrect: Bool) {
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
            self.movieImageView.layer.borderWidth = 0
            self.showNextQuestionOrResults()
            self.noButton.isEnabled.toggle()
            self.yesButton.isEnabled.toggle()
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
          show(quiz: QuizResultsViewModel(
            title: "Этот раунд окончен!",
            text: "Ваш результат: \(correctAnswers)/\(questionsAmount)",
            buttonText: "Сыграть еще раз"))
      } else {
          currentQuestionIndex += 1
          
          questionFactory?.requestNextQuestion()
      }
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        
        let bestGame = statisticService.bestGame
        let message =   """
                        Ваш результат: \(correctAnswers)/\(questionsAmount) 
                        Количество сыгранных квизов: \(statisticService.gamesCount)
                        Рекорд: \(bestGame.correct)/\(bestGame.total) (\(Date().dateTimeString))
                        Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
                        """
        
        let alertModel = AlertModel(
            title: result.title,
            message: message,
            buttonText: result.buttonText) { [weak self] in
                guard let self else { return }
                self.currentQuestionIndex = 0
                self.correctAnswers = 0
                self.questionFactory?.requestNextQuestion()
            }
        alertPresenter.show(in: self, model: alertModel)
    }
}
