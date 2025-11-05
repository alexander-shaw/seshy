//
//  MediaGridPicker.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct MediaGridPicker: View {
    @Environment(\.theme) private var theme
    @Binding var mediaItems: [MediaItem]
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showPhotoPicker = false
    
    let maxItems: Int
    let title: String?
    let subtitle: String?
    
    var onMediaChanged: (() -> Void)?
    
    init(
        mediaItems: Binding<[MediaItem]>,
        maxItems: Int = 4,
        title: String? = nil,
        subtitle: String? = nil,
        onMediaChanged: (() -> Void)? = nil
    ) {
        self._mediaItems = mediaItems
        self.maxItems = maxItems
        self.title = title
        self.subtitle = subtitle
        self.onMediaChanged = onMediaChanged
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            if let title = title {
                Text(title)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.mainText)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.offText)
            }
            
            DraggableMediaGrid(
                mediaItems: $mediaItems,
                maxItems: maxItems,
                spacing: theme.spacing.small,
                onAddMedia: { showPhotoPicker = true },
                onDeleteMedia: { index in
                    if index < mediaItems.count {
                        mediaItems.remove(at: index)
                        updatePositions()
                        onMediaChanged?()
                    }
                },
                onMoveMedia: { source, destination in
                    if source < mediaItems.count && destination < mediaItems.count {
                        let movedItem = mediaItems.remove(at: source)
                        mediaItems.insert(movedItem, at: destination)
                        updatePositions()
                        onMediaChanged?()
                    }
                }
            )
            .frame(height: calculateGridHeight())
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $pickerItems,
            maxSelectionCount: max(0, maxItems - mediaItems.count),
            matching: .any(of: [.images, .videos])
        )
        .onChange(of: pickerItems) { oldValue, newValue in
            Task {
                let newMediaItems = await MediaSelectionHelper.processPickerItems(
                    newValue,
                    maxItems: maxItems - mediaItems.count
                )
                mediaItems.append(contentsOf: newMediaItems)
                updatePositions()
                pickerItems = []
                onMediaChanged?()
            }
        }
    }
    
    private func updatePositions() {
        var updatedItems: [MediaItem] = []
        for (index, item) in mediaItems.enumerated() {
            var updatedItem = item
            updatedItem.position = Int16(index)
            updatedItems.append(updatedItem)
        }
        mediaItems = updatedItems
    }
    
    private func calculateGridHeight() -> CGFloat {
        // Calculate grid height based on number of media items.
        let spacing = theme.spacing.small
        let totalSpacing = spacing * 1  // 1 gap between 2 items.
        let itemSide = (theme.sizes.screenWidth - totalSpacing) / 2

        // If 2 or fewer media items, use 1 row. Otherwise, use 2 rows.
        if mediaItems.count <= 1 {
            return itemSide  // 1 row.
        } else {
            return itemSide * 2 + spacing  // 2 rows + gap.
        }
    }
}

// MARK: Draggable Grid using UIKit:
struct DraggableMediaGrid: UIViewRepresentable {
    @Binding var mediaItems: [MediaItem]
    let maxItems: Int
    let spacing: CGFloat
    var onAddMedia: () -> Void
    var onDeleteMedia: (Int) -> Void
    var onMoveMedia: (Int, Int) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = context.coordinator
        collectionView.dropDelegate = context.coordinator
        collectionView.register(MediaCell.self, forCellWithReuseIdentifier: "MediaCell")
        collectionView.register(AddMediaCell.self, forCellWithReuseIdentifier: "AddMediaCell")
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        if context.coordinator.mediaItems != mediaItems {
            context.coordinator.mediaItems = mediaItems
            uiView.reloadData()
        }
    }
    
    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
        var parent: DraggableMediaGrid
        var mediaItems: [MediaItem]
        
        init(_ parent: DraggableMediaGrid) {
            self.parent = parent
            self.mediaItems = parent.mediaItems
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            let canAddMore = mediaItems.count < parent.maxItems
            return mediaItems.count + (canAddMore ? 1 : 0)
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            // Check if this is the add button cell.
            let isAddButton = indexPath.item == mediaItems.count && mediaItems.count < parent.maxItems
            
            if isAddButton {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "AddMediaCell", for: indexPath)
            } else {
                // Ensure we have a valid index.
                guard indexPath.item < mediaItems.count else {
                    // Fallback to empty cell if index is out of bounds.
                    return collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath)
                }
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as! MediaCell
                let media = mediaItems[indexPath.item]
                cell.configure(with: media)
                cell.onDeleteTapped = { self.parent.onDeleteMedia(indexPath.item) }
                return cell
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let spacing = parent.spacing
            let totalSpacing = spacing * 1  // 1 gap between 2 items.
            let side = (collectionView.frame.width - totalSpacing) / 2
            return CGSize(width: side, height: side)
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if indexPath.item == mediaItems.count && mediaItems.count < parent.maxItems {
                parent.onAddMedia()
            }
        }
        
        // MARK: Drag & Drop:
        func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
            guard indexPath.item < mediaItems.count else { return [] }
            
            let media = mediaItems[indexPath.item]
            guard let image = media.uiImage() else { return [] }
            
            let provider = NSItemProvider(object: image)
            let dragItem = UIDragItem(itemProvider: provider)
            dragItem.localObject = image
            return [dragItem]
        }
        
        func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
            guard let dragItem = coordinator.items.first,
                  let source = dragItem.sourceIndexPath,
                  let destination = coordinator.destinationIndexPath,
                  source != destination,
                  source.item < mediaItems.count,
                  destination.item < mediaItems.count else { return }
            
            // Updates data source atomically within batch updates to prevent snap-back.
            collectionView.performBatchUpdates({
                // Updates data source.
                let movedItem = mediaItems.remove(at: source.item)
                
                // Calculates correct insertion index.
                var insertIndex = destination.item
                if source.item < destination.item {
                    // No adjustment needed when moving forward.
                    insertIndex = destination.item
                }
                
                mediaItems.insert(movedItem, at: insertIndex)
                
                // Updates collection view - this happens atomically with data source update.
                collectionView.moveItem(at: source, to: destination)
            }, completion: { finished in
                if finished {
                    // Updates positions and notify parent after visual update completes.
                    self.updateMediaPositions()
                    self.parent.onMoveMedia(source.item, destination.item)
                }
            })
            
            // Completes the drop operation.
            coordinator.drop(dragItem.dragItem, toItemAt: destination)
        }
        
        private func updateMediaPositions() {
            var updatedItems: [MediaItem] = []
            for (index, item) in mediaItems.enumerated() {
                var updatedItem = item
                updatedItem.position = Int16(index)
                updatedItems.append(updatedItem)
            }
            mediaItems = updatedItems
        }
        
        func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
            session.localDragSession != nil
        }
        
        func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destination: IndexPath?) -> UICollectionViewDropProposal {
            if let destination = destination {
                // Do not allow dropping on the add button.
                if destination.item >= mediaItems.count {
                    return UICollectionViewDropProposal(operation: .forbidden)
                }
            }
            // Uses .insertAtDestinationIndexPath for immediate visual feedback.
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
    }
}

// MARK: Media Cell:
class MediaCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let videoIndicator = UIImageView()
    private let deleteButton = UIButton(type: .custom)
    var onDeleteTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        contentView.addSubview(imageView)
        
        // Video Indicator.
        let videoIcon = UIImage(systemName: "play.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 18, weight: .black)
        )
        videoIndicator.image = videoIcon
        videoIndicator.tintColor = .white
        videoIndicator.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        videoIndicator.layer.cornerRadius = 12
        videoIndicator.contentMode = .center
        videoIndicator.isHidden = true
        contentView.addSubview(videoIndicator)
        
        // Delete Button.
        let icon = UIImage(systemName: "xmark")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        )
        deleteButton.setImage(icon, for: .normal)
        deleteButton.tintColor = .black
        deleteButton.backgroundColor = .white
        deleteButton.layer.cornerRadius = 12
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        contentView.addSubview(deleteButton)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        videoIndicator.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            videoIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            videoIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            videoIndicator.widthAnchor.constraint(equalToConstant: 24),
            videoIndicator.heightAnchor.constraint(equalToConstant: 24),
            
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            deleteButton.widthAnchor.constraint(equalToConstant: 20),
            deleteButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with media: MediaItem) {
        if let image = media.uiImage() {
            imageView.image = image
        }
        videoIndicator.isHidden = !media.isVideo
    }
    
    @objc private func deleteTapped() {
        onDeleteTapped?()
    }
}

// MARK: Add Media Cell:
class AddMediaCell: UICollectionViewCell {
    private let iconView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .black)
        let image = UIImage(systemName: "plus", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .center
        imageView.tintColor = .label
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32)
        ])
        contentView.backgroundColor = UIColor.secondarySystemFill
        contentView.layer.cornerRadius = 12
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
