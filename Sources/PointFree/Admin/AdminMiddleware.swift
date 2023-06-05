import Dependencies
import Foundation
import HttpPipeline
import Models
import PointFreeDependencies
import PointFreeRouter
import Prelude
import Tuple

public func adminMiddleware(conn: Conn<StatusLineOpen, Admin>) async -> Conn<ResponseEnded, Data> {
  @Dependency(\.currentUser) var currentUser
  let route = conn.data
  let conn = conn.map { _ in }

  guard let currentUser = currentUser
  else { return conn.loginAndRedirect() }

  guard currentUser.isAdmin
  else {
    return conn.redirect(to: .home) { $0.flash(.error, "You don't have access to that.") }
  }

  switch route {
  case let .emailPreview(template: template):
    return await emailPreview(conn.map { _ in template })

  case let .episodeCredits(.add(userId: userId, episodeSequence: episodeSequence)):
    return await redeemEpisodeCreditMiddleware(conn.map(const(userId .*. episodeSequence .*. unit)))
      .performAsync()

  case .episodeCredits(.show):
    return await showEpisodeCreditsMiddleware(conn).performAsync()

  case .index:
    return await adminIndex(conn).performAsync()

  case .freeEpisodeEmail(.index):
    return await indexFreeEpisodeEmailMiddleware(conn).performAsync()

  case let .freeEpisodeEmail(.send(episodeId)):
    return await sendFreeEpisodeEmailMiddleware(conn.map { episodeId }).performAsync()

  case .ghost(.index):
    return conn.ghostIndex()

  case let .ghost(.start(userId)):
    return await ghostStartMiddleware(conn.map(const(currentUser .*. userId .*. unit)))
      .performAsync()

  case let .newBlogPostEmail(.send(blogPostId, formData, isTest)):
    return await sendNewBlogPostEmailMiddleware(
      conn.map { blogPostId .*. formData .*. isTest .*. unit }
    )
    .performAsync()

  case .newBlogPostEmail(.index):
    return conn.showNewBlogPostEmail()

  case let
    .newEpisodeEmail(.send(episodeId, subscriberAnnouncement, nonSubscriberAnnouncement, isTest)):
    return await sendNewEpisodeEmailMiddleware(
      conn.map {
        episodeId .*. subscriberAnnouncement .*. nonSubscriberAnnouncement .*. isTest .*. unit
      }
    )
    .performAsync()

  case .newEpisodeEmail(.show):
    return await showNewEpisodeEmailMiddleware(conn.map { unit }).performAsync()
  }
}
