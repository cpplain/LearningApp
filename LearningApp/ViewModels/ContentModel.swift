//
//  ContentModel.swift
//  LearningApp
//
//  Created by Christopher Plain on 7/21/21.
//

import Foundation

class ContentModel: ObservableObject {
    @Published var modules = [Module]()
    @Published var correctAnswerIndex: Int?
    @Published var currentLesson: Lesson?
    @Published var currentModule: Module?
    @Published var currentModuleIndex: Int?
    @Published var currentQuestion: Question?
    @Published var currentStyledText: NSAttributedString?
    @Published var lessonLinkSelected: Int?
    @Published var testLinkSelected: Int?
    var currentLessonIndex: Int?
    var currentQuestionIndex: Int?
    var styleData: Data?
    var testScore = 0
    
    init() {
        getLocalData()
        getRemoteData()
        getStyleData()
    }
    
    func getLocalData() {
        let url = Bundle.main.url(forResource: "data", withExtension: "json")
        do {
            let data = try Data(contentsOf: url!)
            let decoder = JSONDecoder()
            let modules = try decoder.decode([Module].self, from: data)
            self.modules += modules
        } catch {
            print(error)
        }
    }
    
    func getRemoteData() {
        let urlString = "https://raw.githubusercontent.com/christopherplain/learning-app-data/main/data2.json"
        let url = URL(string: urlString)
        guard url != nil else {
            return
        }
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url!) { (data, response, error) in
            guard error == nil else {
                return
            }
            do {
                let decoder = JSONDecoder()
                let modules = try decoder.decode([Module].self, from: data!)
                DispatchQueue.main.async {
                    self.modules += modules
                }
            } catch {
                print(error)
            }
        }
        dataTask.resume()
    }
    
    func getStyleData() {
        let url = Bundle.main.url(forResource: "style", withExtension: "html")
        do {
            styleData = try Data(contentsOf: url!)
        } catch {
            print(error)
        }
    }
    
    func beginModule(_ index: Int) {
        currentModule = modules[index]
    }
    
    func beginLesson(_ index: Int) {
        currentLesson = currentModule?.content.lessons[index]
        currentLessonIndex = index
        currentStyledText = styleText(currentLesson!.explanation)
    }
    
    func beginTest(_ moduleIndex: Int) {
        beginModule(moduleIndex)
        currentQuestionIndex = 0
        currentQuestion = currentModule!.test.questions[currentQuestionIndex!]
        currentStyledText = styleText(currentQuestion!.content)
        correctAnswerIndex = currentQuestion!.correctIndex
    }
    
    func hasNextLesson() -> Bool {
        return currentLessonIndex! + 1 < currentModule!.content.lessons.count
    }
    
    func hasNextQuestion() -> Bool {
        return currentQuestionIndex! + 1 < currentModule!.test.questions.count
    }
    
    func nextLesson() {
        if hasNextLesson() {
            beginLesson(currentLessonIndex! + 1)
        } else {
            currentLesson = nil
            currentLessonIndex = nil
            lessonLinkSelected = nil
        }
    }
    
    func nextQuestion() {
        if hasNextQuestion() {
            currentQuestionIndex! += 1
            currentQuestion = currentModule!.test.questions[currentQuestionIndex!]
            currentStyledText = styleText(currentQuestion!.content)
            correctAnswerIndex = currentQuestion!.correctIndex
        } else {
            correctAnswerIndex = nil
            currentQuestion = nil
            currentQuestionIndex = nil
            currentStyledText = nil
        }
    }
    
    func scoreQuestion(for selectedAnswerIndex: Int) {
        if selectedAnswerIndex == correctAnswerIndex {
            testScore += 1
        }
    }

    func styleText(_ htmlString: String) -> NSAttributedString {
        var resultString = NSAttributedString()
        var data = Data()
        if styleData != nil {
            data.append(styleData!)
        }
        data.append(Data(htmlString.utf8))
        if let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ) {
            resultString = attributedString
        }
        return resultString
    }
}
