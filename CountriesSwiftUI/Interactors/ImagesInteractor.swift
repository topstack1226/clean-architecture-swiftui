//
//  ImagesInteractor.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 09.11.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

protocol ImagesInteractor {
    func load(image: Binding<Loadable<UIImage>>, url: URL?) -> AnyCancellable
}

struct RealImagesInteractor: ImagesInteractor {
    
    let webRepository: ImageWebRepository
    let inMemoryCache: ImageCacheRepository
    let appState: AppState
    private let memoryWarningSubscription: AnyCancellable
    
    init(webRepository: ImageWebRepository,
         inMemoryCache: ImageCacheRepository,
         memoryWarning: AnyPublisher<Void, Never>,
         appState: AppState) {
        self.webRepository = webRepository
        self.inMemoryCache = inMemoryCache
        self.appState = appState
        memoryWarningSubscription = memoryWarning.sink { [inMemoryCache] _ in
            inMemoryCache.purgeCache()
        }
    }
    
    func load(image: Binding<Loadable<UIImage>>, url: URL?) -> AnyCancellable {
        guard let url = url else {
            image.wrappedValue = .notRequested; return .cancelled
        }
        image.wrappedValue = .isLoading(last: image.wrappedValue.value)
        return inMemoryCache.cachedImage(for: url.imageCacheKey)
            .catch { _ in
                self.webRepository.load(imageURL: url, width: 300)
            }
            .sinkToLoadable {
                image.wrappedValue = $0
                if let image = $0.value {
                    self.inMemoryCache.cache(image: image, key: url.imageCacheKey)
                }
            }
    }
}

extension URL {
    var imageCacheKey: ImageCacheKey {
        return absoluteString
    }
}

struct StubImagesInteractor: ImagesInteractor {
    func load(image: Binding<Loadable<UIImage>>, url: URL?) -> AnyCancellable {
        return .cancelled
    }
}
