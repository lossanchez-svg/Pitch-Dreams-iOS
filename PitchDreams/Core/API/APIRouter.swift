import Foundation

enum APIRouter: APIEndpoint {
    // MARK: - Auth
    case parentLogin(email: String, password: String)
    case childLogin(parentEmail: String, nickname: String, pin: String)

    // MARK: - Auth (non-v1)
    case signup(email: String, password: String)
    case forgotPassword(email: String)
    case resetPassword(token: String, password: String)

    // MARK: - Parent
    case listChildren
    case updateChildPermissions(childId: String, permissions: PermissionsUpdate)
    case exportChildData(childId: String)
    case deleteChild(childId: String)

    // MARK: - Parent (non-v1)
    case createChild(parentId: String, body: CreateChildBody)
    case addChild(body: CreateChildBody) // Authenticated version for existing parents
    case setChildPin(childId: String, pin: String)

    // MARK: - Parent (v1)
    case resetChildProgress(childId: String)
    case deleteParentAccount

    // MARK: - Child Profile
    case getProfile(childId: String)
    case updateAvatar(childId: String, avatarId: String)

    // MARK: - Sessions
    case listSessions(childId: String, limit: Int = 20)
    case createSession(childId: String, body: CreateSessionBody)
    case createQuickSession(childId: String, body: QuickSessionBody)

    // MARK: - Activities
    case listActivities(childId: String, limit: Int = 10)
    case createActivity(childId: String, body: CreateActivityBody)

    // MARK: - Check-Ins
    case listCheckIns(childId: String, limit: Int = 10)
    case createCheckIn(childId: String, body: CreateCheckInBody)
    case createQuickCheckIn(childId: String, body: QuickCheckInBody)
    case todayCheckIn(childId: String)
    case updateCheckIn(childId: String, checkInId: String, body: UpdateCheckInBody)

    // MARK: - Trends & Nudge
    case getTrends(childId: String, weeks: Int = 4)
    case getNudge(childId: String)

    // MARK: - Arcs
    case listArcs(childId: String)
    case activeArc(childId: String)
    case startArc(childId: String, body: StartArcBody)
    case updateArcState(childId: String, arcStateId: String, body: UpdateArcBody)
    case updateArcProgress(childId: String, body: ArcProgressBody)
    case arcSuggestion(childId: String)

    // MARK: - Drills
    case logDrill(childId: String, body: LogDrillBody)
    case drillStats(childId: String)

    // MARK: - Lessons
    case lessonProgress(childId: String)
    case updateLessonProgress(childId: String, lessonId: String, body: LessonProgressBody)
    case submitQuiz(childId: String, lessonId: String, body: QuizResultBody)

    // MARK: - Streaks
    case getStreaks(childId: String)
    case checkFreeze(childId: String)
    case recordMilestone(childId: String, body: MilestoneBody)

    // MARK: - Tags
    case focusTags
    case highlightTags
    case nextFocusTags

    // MARK: - Entities
    case listFacilities
    case recentFacilities(limit: Int = 5)
    case createFacility(body: CreateFacilityBody)
    case listCoaches
    case createCoach(body: CreateCoachBody)
    case listPrograms
    case createProgram(body: CreateProgramBody)

    // MARK: - APIEndpoint

    var apiBasePath: String {
        switch self {
        case .signup, .forgotPassword, .resetPassword, .createChild, .addChild, .setChildPin:
            return "/api"
        default:
            return Constants.apiBasePath
        }
    }

    var path: String {
        switch self {
        case .parentLogin, .childLogin: return "/auth/token"
        case .signup: return "/auth/signup"
        case .forgotPassword: return "/auth/forgot-password"
        case .resetPassword: return "/auth/reset-password"
        case .listChildren: return "/parent/children"
        case .createChild: return "/parent/children"
        case .addChild: return "/parent/children"
        case .setChildPin(let id, _): return "/parent/children/\(id)/pin"
        case .resetChildProgress(let id): return "/parent/reset-progress/\(id)"
        case .deleteParentAccount: return "/parent/account"
        case .updateChildPermissions(let id, _): return "/parent/children/\(id)/permissions"
        case .exportChildData(let id): return "/parent/children/\(id)/export"
        case .deleteChild(let id): return "/parent/children/\(id)"
        case .getProfile(let id): return "/children/\(id)/profile"
        case .updateAvatar(let id, _): return "/children/\(id)/profile"
        case .listSessions(let id, _): return "/children/\(id)/sessions"
        case .createSession(let id, _): return "/children/\(id)/sessions"
        case .createQuickSession(let id, _): return "/children/\(id)/sessions/quick"
        case .listActivities(let id, _): return "/children/\(id)/activities"
        case .createActivity(let id, _): return "/children/\(id)/activities"
        case .listCheckIns(let id, _): return "/children/\(id)/check-ins"
        case .createCheckIn(let id, _): return "/children/\(id)/check-ins"
        case .createQuickCheckIn(let id, _): return "/children/\(id)/check-ins/quick"
        case .todayCheckIn(let id): return "/children/\(id)/check-ins/today"
        case .updateCheckIn(let id, let ciId, _): return "/children/\(id)/check-ins/\(ciId)"
        case .getTrends(let id, _): return "/children/\(id)/trends"
        case .getNudge(let id): return "/children/\(id)/nudge"
        case .listArcs(let id): return "/children/\(id)/arcs"
        case .activeArc(let id): return "/children/\(id)/arcs/active"
        case .startArc(let id, _): return "/children/\(id)/arcs"
        case .updateArcState(let id, let asId, _): return "/children/\(id)/arcs/\(asId)"
        case .updateArcProgress(let id, _): return "/children/\(id)/arcs/progress"
        case .arcSuggestion(let id): return "/children/\(id)/arcs/suggestion"
        case .logDrill(let id, _): return "/children/\(id)/drills"
        case .drillStats(let id): return "/children/\(id)/drills/stats"
        case .lessonProgress(let id): return "/children/\(id)/lessons/progress"
        case .updateLessonProgress(let id, let lid, _): return "/children/\(id)/lessons/\(lid)/progress"
        case .submitQuiz(let id, let lid, _): return "/children/\(id)/lessons/\(lid)/quiz"
        case .getStreaks(let id): return "/children/\(id)/streaks"
        case .checkFreeze(let id): return "/children/\(id)/streaks/freeze-check"
        case .recordMilestone(let id, _): return "/children/\(id)/streaks/milestones"
        case .focusTags: return "/tags/focus"
        case .highlightTags: return "/tags/highlights"
        case .nextFocusTags: return "/tags/next-focus"
        case .listFacilities: return "/facilities"
        case .recentFacilities: return "/facilities/recent"
        case .createFacility: return "/facilities"
        case .listCoaches: return "/coaches"
        case .createCoach: return "/coaches"
        case .listPrograms: return "/programs"
        case .createProgram: return "/programs"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .parentLogin, .childLogin, .createSession, .createQuickSession,
             .createActivity, .createCheckIn, .createQuickCheckIn,
             .startArc, .updateArcProgress, .logDrill,
             .updateLessonProgress, .submitQuiz, .checkFreeze, .recordMilestone,
             .createFacility, .createCoach, .createProgram,
             .signup, .forgotPassword, .resetPassword, .createChild, .addChild, .resetChildProgress:
            return .post
        case .updateChildPermissions, .updateCheckIn, .updateArcState, .updateAvatar:
            return .patch
        case .setChildPin:
            return .put
        case .deleteChild, .deleteParentAccount:
            return .delete
        default:
            return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .listSessions(_, let limit): return [URLQueryItem(name: "limit", value: "\(limit)")]
        case .listActivities(_, let limit): return [URLQueryItem(name: "limit", value: "\(limit)")]
        case .listCheckIns(_, let limit): return [URLQueryItem(name: "limit", value: "\(limit)")]
        case .getTrends(_, let weeks): return [URLQueryItem(name: "weeks", value: "\(weeks)")]
        case .recentFacilities(let limit): return [URLQueryItem(name: "limit", value: "\(limit)")]
        default: return nil
        }
    }

    var body: (any Encodable)? {
        switch self {
        case .parentLogin(let email, let password):
            return ParentLoginBody(email: email, password: password)
        case .childLogin(let parentEmail, let nickname, let pin):
            return ChildLoginBody(parentEmail: parentEmail, nickname: nickname, pin: pin)
        case .signup(let email, let password):
            return SignupBody(email: email, password: password)
        case .forgotPassword(let email):
            return ForgotPasswordBody(email: email)
        case .resetPassword(let token, let password):
            return ResetPasswordBody(token: token, password: password)
        case .createChild(_, let body): return body
        case .addChild(let body): return body
        case .setChildPin(_, let pin): return SetPinBody(pin: pin)
        case .createSession(_, let body): return body
        case .createQuickSession(_, let body): return body
        case .createActivity(_, let body): return body
        case .createCheckIn(_, let body): return body
        case .createQuickCheckIn(_, let body): return body
        case .updateCheckIn(_, _, let body): return body
        case .updateChildPermissions(_, let body): return body
        case .startArc(_, let body): return body
        case .updateArcState(_, _, let body): return body
        case .updateArcProgress(_, let body): return body
        case .logDrill(_, let body): return body
        case .updateLessonProgress(_, _, let body): return body
        case .submitQuiz(_, _, let body): return body
        case .recordMilestone(_, let body): return body
        case .createFacility(let body): return body
        case .createCoach(let body): return body
        case .createProgram(let body): return body
        case .updateAvatar(_, let avatarId): return ["avatarId": avatarId] as [String: String]
        default: return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .parentLogin, .childLogin, .signup, .forgotPassword, .resetPassword, .createChild:
            return false
        default:
            return true
        }
    }
}

// MARK: - Request Bodies

struct ParentLoginBody: Encodable { let email: String; let password: String }
struct ChildLoginBody: Encodable { let parentEmail: String; let nickname: String; let pin: String }
struct SignupBody: Encodable { let email: String; let password: String }
struct ForgotPasswordBody: Encodable { let email: String }
struct ResetPasswordBody: Encodable { let token: String; let password: String }
struct SetPinBody: Encodable { let pin: String }
struct CreateChildBody: Encodable {
    let nickname: String
    let age: Int
    let position: String?
    let goals: [String]?
    let avatarId: String
    let avatarColor: String?
    let freeTextEnabled: Bool?
    let trainingWindowStart: String?
    let trainingWindowEnd: String?
    var parentId: String?
}
struct SignupResponse: Decodable { let success: Bool; let parentId: String }
struct CreateChildResponse: Decodable { let success: Bool; let childId: String }
struct CreateSessionBody: Codable { var activityType: String?; let effortLevel: Int; let mood: String; let duration: Int; var win: String?; var focus: String? }
struct QuickSessionBody: Codable { let type: String; let duration: Int; let effort: Int }
struct CreateActivityBody: Encodable { let activityType: String; let durationMinutes: Int; let gameIQImpact: String; var focusTagIds: [String]?; var highlightIds: [String]?; var nextFocusIds: [String]? }
struct CreateCheckInBody: Encodable { let energy: Int; let soreness: String; let focus: Int; let mood: String; let timeAvail: Int; let painFlag: Bool }
struct QuickCheckInBody: Encodable { let mood: String; var timeAvail: Int? }
struct UpdateCheckInBody: Encodable { var qualityRating: Int?; var completed: Bool?; var activityId: String? }
struct PermissionsUpdate: Encodable { let freeTextEnabled: Bool; let voiceEnabled: Bool; var coachPersonality: String?; var trainingWindowStart: String?; var trainingWindowEnd: String? }
struct StartArcBody: Encodable { let arcId: String }
struct UpdateArcBody: Encodable { var action: String?; var reason: String? }
struct ArcProgressBody: Encodable { let sessionMode: String; let sessionCompleted: Bool }
struct LogDrillBody: Encodable { let drillKey: String; var repsCount: Int?; var confidence: Int? }
struct LessonProgressBody: Encodable { let completed: Bool }
struct QuizResultBody: Encodable { let score: Int; let total: Int }
struct MilestoneBody: Encodable { let milestone: Int }
struct CreateFacilityBody: Encodable { let name: String; var city: String?; var isSaved: Bool? }
struct CreateCoachBody: Encodable { let displayName: String; var isSaved: Bool? }
struct CreateProgramBody: Encodable { let name: String; let type: String; var isSaved: Bool? }
