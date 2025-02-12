import Database
import Dependencies
import Either
import HttpPipeline
import Models
import ModelsTestSupport
import PointFreePrelude
import PointFreeRouter
import PointFreeTestSupport
import Prelude
import SnapshotTesting
import XCTest

@testable import PointFree

#if !os(Linux)
  import WebKit
#endif

@MainActor
class EnterpriseTests: TestCase {
  @Dependency(\.envVars) var envVars

  override func setUp() async throws {
    try await super.setUp()
    //SnapshotTesting.isRecording = true
  }

  func testLanding_LoggedOut() async throws {
    let account = EnterpriseAccount.mock

    await withDependencies {
      $0.database.fetchEnterpriseAccountForDomain = { _ in account }
    } operation: {
      let req = request(to: .enterprise(account.domain))
      let conn = connection(from: req)
      await assertSnapshot(matching: await siteMiddleware(conn), as: .conn)

      #if !os(Linux)
        if self.isScreenshotTestingAvailable {
          await assertSnapshots(
            matching: await siteMiddleware(conn),
            as: [
              "desktop": .connWebView(size: .init(width: 1100, height: 700)),
              "mobile": .connWebView(size: .init(width: 500, height: 700)),
            ]
          )
        }
      #endif
    }
  }

  func testLanding_NonExistentEnterpriseAccount() async throws {
    let account = EnterpriseAccount.mock

    await withDependencies {
      $0.database.fetchEnterpriseAccountForDomain = { _ in throw unit }
    } operation: {
      let req = request(to: .enterprise(account.domain))
      let conn = connection(from: req)
      await assertSnapshot(matching: await siteMiddleware(conn), as: .conn)
    }
  }

  func testLanding_AlreadySubscribedToEnterprise() async throws {
    let subscriptionId = Subscription.ID(uuidString: "00000000-0000-0000-0000-012387451903")!
    var account = EnterpriseAccount.mock
    account.subscriptionId = subscriptionId
    var user = User.mock
    user.subscriptionId = subscriptionId

    await withDependencies {
      $0.database.fetchEnterpriseAccountForDomain = { _ in account }
    } operation: {
      let req = request(to: .enterprise(account.domain), session: .loggedIn(as: user))
      let conn = connection(from: req)
      await assertSnapshot(matching: await siteMiddleware(conn), as: .conn)
    }
  }

  func testAcceptInvitation_LoggedOut() async throws {
    let account = EnterpriseAccount.mock

    let req = request(
      to: .enterprise(account.domain, .acceptInvite(email: "baddata", userId: "baddata")),
      session: .loggedOut
    )
    let conn = connection(from: req)
    await assertSnapshot(matching: await siteMiddleware(conn), as: .conn)
  }

  func testAcceptInvitation_BadEmail() async throws {
    var account = EnterpriseAccount.mock
    account.domain = "pointfree.co"
    let userId = User.ID(uuidString: "00000000-0000-0000-0000-123456789012")!
    let encryptedUserId = Encrypted(userId.rawValue.uuidString, with: self.envVars.appSecret)!
    var loggedInUser = User.mock
    loggedInUser.id = userId
    loggedInUser.subscriptionId = nil

    await withDependencies {
      $0.database = .mock
      $0.database.fetchEnterpriseAccountForDomain = { _ in account }
      $0.database.fetchSubscriptionById = { _ in throw unit }
    } operation: {
      let req = request(
        to: .enterprise(account.domain, .acceptInvite(email: "baddata", userId: encryptedUserId)),
        session: .loggedIn(as: loggedInUser)
      )
      let conn = connection(from: req)
      await assertSnapshot(matching: await siteMiddleware(conn), as: .conn)
    }
  }

  func testAcceptInvitation_BadUserId() async throws {
    var account = EnterpriseAccount.mock
    account.domain = "pointfree.co"
    let encryptedEmail = Encrypted("blob@pointfree.co", with: self.envVars.appSecret)!
    let userId = User.ID(uuidString: "00000000-0000-0000-0000-123456789012")!
    var loggedInUser = User.mock
    loggedInUser.id = userId
    loggedInUser.subscriptionId = nil

    await withDependencies {
      $0.database = .mock
      $0.database.fetchEnterpriseAccountForDomain = { _ in account }
      $0.database.fetchSubscriptionById = { _ in throw unit }
    } operation: {
      let req = request(
        to: .enterprise(account.domain, .acceptInvite(email: encryptedEmail, userId: "baddata")),
        session: .loggedIn(as: loggedInUser)
      )
      let conn = connection(from: req)
      await assertSnapshot(matching: await siteMiddleware(conn), as: .conn)
    }
  }

  func testAcceptInvitation_EmailDoesntMatchEnterpriseDomain() async throws {
    var account = EnterpriseAccount.mock
    account.domain = "pointfree.co"
    let encryptedEmail = Encrypted("blob@pointfree.biz", with: self.envVars.appSecret)!
    let userId = User.ID(uuidString: "00000000-0000-0000-0000-123456789012")!
    let encryptedUserId = Encrypted(userId.rawValue.uuidString, with: self.envVars.appSecret)!
    var loggedInUser = User.mock
    loggedInUser.id = userId
    loggedInUser.subscriptionId = nil

    await withDependencies {
      $0.database = .mock
      $0.database.fetchEnterpriseAccountForDomain = { _ in account }
      $0.database.fetchSubscriptionById = { _ in throw unit }
    } operation: {
      let req = request(
        to: .enterprise(
          account.domain, .acceptInvite(email: encryptedEmail, userId: encryptedUserId)),
        session: .loggedIn(as: loggedInUser)
      )
      let conn = connection(from: req)
      await assertSnapshot(matching: await siteMiddleware(conn), as: .conn)
    }
  }

  func testAcceptInvitation_RequesterUserDoesntMatchAccepterUserId() async throws {
    var account = EnterpriseAccount.mock
    account.domain = "pointfree.co"
    let encryptedEmail = Encrypted("blob@pointfree.co", with: self.envVars.appSecret)!
    let userId = User.ID(uuidString: "00000000-0000-0000-0000-123456789012")!
    let encryptedUserId = Encrypted(userId.rawValue.uuidString, with: self.envVars.appSecret)!
    var loggedInUser = User.mock
    loggedInUser.id = User.ID(uuidString: "DEADBEEF-0000-0000-0000-123456789012")!

    await withDependencies {
      $0.database = .mock
      $0.database.fetchEnterpriseAccountForDomain = { _ in account }
      $0.database.fetchSubscriptionById = { _ in throw unit }
    } operation: {
      let req = request(
        to: .enterprise(
          account.domain, .acceptInvite(email: encryptedEmail, userId: encryptedUserId)),
        session: .loggedIn(as: loggedInUser)
      )
      let conn = connection(from: req)
      await assertSnapshot(matching: await siteMiddleware(conn), as: .conn)
    }
  }

  func testAcceptInvitation_EnterpriseAccountDoesntExist() async throws {
    await withDependencies {
      $0.database.fetchEnterpriseAccountForDomain = { _ in throw unit }
      $0.database.fetchSubscriptionById = { _ in throw unit }
    } operation: {
      var account = EnterpriseAccount.mock
      account.domain = "pointfree.co"
      let encryptedEmail = Encrypted("blob@pointfree.co", with: self.envVars.appSecret)!
      let userId = User.ID(uuidString: "00000000-0000-0000-0000-123456789012")!
      let encryptedUserId = Encrypted(userId.rawValue.uuidString, with: self.envVars.appSecret)!
      var loggedInUser = User.mock
      loggedInUser.id = User.ID(uuidString: "DEADBEEF-0000-0000-0000-123456789012")!

      let req = request(
        to: .enterprise(
          account.domain, .acceptInvite(email: encryptedEmail, userId: encryptedUserId)),
        session: .loggedIn(as: loggedInUser)
      )
      let conn = connection(from: req)
      await assertSnapshot(matching: await siteMiddleware(conn), as: .conn)
    }
  }

  func testAcceptInvitation_HappyPath() async throws {
    var account = EnterpriseAccount.mock
    account.domain = "pointfree.co"
    let encryptedEmail = Encrypted("blob@pointfree.co", with: self.envVars.appSecret)!
    let userId = User.ID(uuidString: "00000000-0000-0000-0000-123456789012")!
    let encryptedUserId = Encrypted(userId.rawValue.uuidString, with: self.envVars.appSecret)!
    var loggedInUser = User.mock
    loggedInUser.id = userId
    loggedInUser.subscriptionId = nil

    await withDependencies {
      $0.database = .mock
      $0.database.fetchEnterpriseAccountForDomain = { _ in account }
      $0.database.fetchSubscriptionById = { _ in throw unit }
    } operation: {
      let req = request(
        to: .enterprise(
          account.domain, .acceptInvite(email: encryptedEmail, userId: encryptedUserId)),
        session: .loggedIn(as: loggedInUser)
      )
      let conn = connection(from: req)
      await assertSnapshot(matching: await siteMiddleware(conn), as: .conn)
    }

    // todo: more verifications that subscription was linked
  }

  // todo: flow for when user already has sub
  // todo: flow for when user has canceled sub
  // todo: flow for enterprise account that is past due
}
