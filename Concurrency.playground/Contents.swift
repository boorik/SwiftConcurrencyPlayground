import UIKit

class World {
    var potions = 3
}

class WorldMutex {
    var potions = 3
    let potionLock = NSLock()
    func playerDrinkPotion(_ player: Player) {
        potionLock.lock()
        if potions > .zero {
            print("\(player.id) can drink a potion 🤩")
            Thread.sleep(forTimeInterval: TimeInterval(1))
            potions -= 1
        } else {
            print("oh nooo 😞, no potion left for \(player.id)")
        }
        potionLock.unlock()
    }
}

actor WorldActor {
    var potions = 3
    func playerDrinkPotion(_ player: Player) async {
        if potions > .zero {
            print("\(player.id) can drink a potion 🤩")
            await Task.sleep(2 * 1_000_000_000)
            potions -= 1
        } else {
            print("oh nooo 😞, no potion left for \(player.id)")
        }
    }
}

struct Player {
    let id: Int
    func drinkAPotion(from world: World) {
        if world.potions > .zero {
            print("hey I can drink a potion 🤩")
            Thread.sleep(forTimeInterval: TimeInterval.random(in: 1...3))
            world.potions -= 1
        } else {
            print("oh nooo 😞, no potion left")
        }
    }

    func drinkAPotionAsync(from world: World) async {
        if world.potions > .zero {
            print("hey I can drink a potion 🤩")
//            Thread.sleep(forTimeInterval: TimeInterval(1))
            await Task.sleep(2 * 1_000_000_000)
            world.potions -= 1
        } else {
            print("oh nooo 😞, no potion left")
        }
    }
}

struct UseCase {
    static func processInMain() {
        let world = World()
        let players = (0...9).map { Player(id: $0)}

        players.forEach { player in
            DispatchQueue.main.async {
                player.drinkAPotion(from: world)
            }
        }
    }

    static func processInConcurrency() {
        let world = World()
        let players = (0...9).map { Player(id: $0)}

        players.forEach { player in
            DispatchQueue.global(qos: .utility).async {
                player.drinkAPotion(from: world)
            }
        }
    }

    static func processInConcurrencyWithMutex() {
        let world = WorldMutex()
        let players = (0...9).map { Player(id: $0)}

        players.forEach { player in
            DispatchQueue.global(qos: .utility).async {
                world.playerDrinkPotion(player)
            }
        }
    }

// trying to make race condition with asyncgroup
    static func processTaskGroup() {
        let world = World()
        let players = (0...9).map { Player(id: $0)}
        Task {
            await withTaskGroup(of: Void.self) { group in
                for player in players {
                    group.addTask {
                        await player.drinkAPotionAsync(from: world)
                    }
                }
            }
            print("world.potions: \(world.potions)")
        }
    }
// fix race condition with Actor
    static func processTaskGroupWithActor() {
        let world = WorldActor()
        let players = (0...9).map { Player(id: $0)}
        Task {
            await withTaskGroup(of: Void.self) { group in
                for player in players {
                    group.addTask {
                        await world.playerDrinkPotion(player)
                    }
                }
            }
            print("world.potions: \(await world.potions)")
        }
    }

    static func processTask() {
        let world = World()
        let players = (0...9).map { Player(id: $0)}
        Task {
            for player in players {
                await player.drinkAPotionAsync(from: world)
            }
            print("world.potions: \(world.potions)")
        }
    }

    static func processUnmanaged() {
        let world = World()
        let players = (0...9).map { Player(id: $0)}
        Task {
            async let _ = await players[0].drinkAPotionAsync(from: world)
            async let _ = await players[1].drinkAPotionAsync(from: world)
            async let _ = await players[2].drinkAPotionAsync(from: world)
            async let _ = await players[3].drinkAPotionAsync(from: world)
            async let _ = await players[4].drinkAPotionAsync(from: world)
            async let _ = await players[5].drinkAPotionAsync(from: world)
            async let _ = await players[6].drinkAPotionAsync(from: world)
            async let _ = await players[7].drinkAPotionAsync(from: world)
            async let _ = await players[8].drinkAPotionAsync(from: world)
            async let _ = await players[9].drinkAPotionAsync(from: world)
        }
    }
}

//UseCase.processInMain()
//UseCase.processInConcurrency()
//UseCase.processInConcurrencyWithMutex()
// should show race conditions
//UseCase.processTaskGroup()
UseCase.processTask()
//UseCase.processUnmanaged()
//UseCase.processTaskGroupWithActor()
