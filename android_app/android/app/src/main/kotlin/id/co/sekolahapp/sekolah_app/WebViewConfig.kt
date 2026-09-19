package id.co.sekolahapp.sekolah_app

import android.Manifest
import android.content.pm.PackageManager
import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity

class FlutterWebChromeClient(private val activity: FlutterActivity) : WebChromeClient() {
    override fun onPermissionRequest(request: PermissionRequest?) {
        if (request == null) {
            super.onPermissionRequest(request)
            return
        }

        val resources = request.resources
        val permissions = mutableListOf<String>()
        val grantedResources = mutableListOf<String>()

        for (resource in resources) {
            when (resource) {
                PermissionRequest.RESOURCE_VIDEO_CAPTURE -> {
                    permissions.add(Manifest.permission.CAMERA)
                    if (ContextCompat.checkSelfPermission(
                            activity,
                            Manifest.permission.CAMERA
                        ) == PackageManager.PERMISSION_GRANTED
                    ) {
                        grantedResources.add(PermissionRequest.RESOURCE_VIDEO_CAPTURE)
                    }
                }
                PermissionRequest.RESOURCE_AUDIO_CAPTURE -> {
                    permissions.add(Manifest.permission.RECORD_AUDIO)
                    if (ContextCompat.checkSelfPermission(
                            activity,
                            Manifest.permission.RECORD_AUDIO
                        ) == PackageManager.PERMISSION_GRANTED
                    ) {
                        grantedResources.add(PermissionRequest.RESOURCE_AUDIO_CAPTURE)
                    }
                }
            }
        }

        if (grantedResources.isNotEmpty()) {
            request.grant(grantedResources.toTypedArray())
        } else {
            request.deny()
        }
    }
}
