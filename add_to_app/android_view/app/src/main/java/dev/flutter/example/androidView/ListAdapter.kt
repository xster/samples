// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.example.androidView

import android.app.Activity
import android.content.Context
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import dev.flutter.example.androidView.databinding.AndroidCardBinding
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.*
import kotlin.random.Random

/**
 * A demo-specific implementation of a [RecyclerView.Adapter] to setup the demo environment used
 * to display view-level Flutter cells inside a list.
 *
 * The only instructional parts of this class are to show when to call
 * [FlutterViewEngine.attachFlutterView] and [FlutterViewEngine.detachActivity] on a
 * [FlutterViewEngine] equivalent class that you may want to create in your own application.
 */
class ListAdapter(activity: Activity) : RecyclerView.Adapter<ListAdapter.Cell>() {
    // Save the previous cells determined to be Flutter cells to avoid a confusing visual effect
    // that the Flutter cells change position when scrolling back.
    var previousFlutterCells = TreeSet<Int>();

    private val matchParentLayout = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)

    private val random = Random.Default
    private val flutterView = FlutterView(activity)
    private val flutterEngineGroup = FlutterEngineGroup();

    /**
     * A [RecyclerView.ViewHolder] based on the `android_card` layout XML.
     */
    inner class Cell(val binding: AndroidCardBinding) : RecyclerView.ViewHolder(binding.root) {
        var viewEngine: FlutterViewEngine? = null
    }

    override fun onCreateViewHolder(viewGroup: ViewGroup, viewType: Int): Cell {
        val binding = AndroidCardBinding.inflate(LayoutInflater.from(viewGroup.context), viewGroup, false)

        // Let the default view holder have an "Android card" inflated from the layout XML. When
        // needed, hide the Android card and show a Flutter one instead.
        return Cell(binding)
    }

    override fun onBindViewHolder(cell: Cell, position: Int) {
        // While scrolling forward, if no Flutter is presently showing, let the next one have a 1/3
        // chance of being Flutter.
        //
        // While scrolling backward, let it be deterministic, and only show cells that were
        // previously Flutter cells as Flutter cells.
        if (previousFlutterCells.contains(position)
            || ((previousFlutterCells.isEmpty() || position > previousFlutterCells.last())
                && random.nextInt(1) == 0)) {

            val flutterEngine = flutterEngineGroup.createAndRunEngine(activity.getApplicationContext(), DartExecutor.DartEntrypoint(
            FlutterInjector.instance().flutterLoader().findAppBundlePath(),
            "showCell"))
            val flutterViewEngine = FlutterViewEngine(flutterEngine)
            flutterViewEngine.attachToActivity(activity)

            // Add the Flutter card and hide the Android card for the cells chosen to be Flutter
            // cells.
            cell.binding.root.addView(flutterView, matchParentLayout)
            cell.binding.androidCard.visibility = View.GONE

            cell.viewEngine = flutterViewEngine
            // Keep track that this position has once been a Flutter cell. Let it be a Flutter cell
            // again when scrolling back to this position.
            previousFlutterCells.add(position)

            // This is what makes the Flutter cell start rendering.
            flutterViewEngine.attachFlutterView(flutterView)
            // Tell Flutter which index it's at so Flutter could show the cell number too in its
            // own widget tree.
            MethodChannel(flutterViewEngine.engine.dartExecutor, "dev.flutter.example/cell").invokeMethod("setCellNumber", position)
        } else {
            // If it's not selected as a Flutter cell, just show the Android card.
            cell.binding.androidCard.visibility = View.VISIBLE
            cell.binding.cellNumber.text = position.toString();
        }
    }

    override fun getItemCount() = 100

    override fun onViewRecycled(cell: Cell) {
        if (cell.viewEngine != null) {
            cell.binding.root.removeView(flutterView)
            cell.viewEngine.detachFlutterView()
            cell.viewEngine.detachFromActivity()
            cell.viewEngine = null
        }
        super.onViewRecycled(cell)
    }
}
