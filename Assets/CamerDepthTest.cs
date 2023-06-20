using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CamerDepthTest : MonoBehaviour
{
    public Shader _shader;
    private Material _material;
    private readonly Vector4 RayleighSct = new Vector4(5.8f, 13.5f, 33.1f, 0.0f) * 0.000001f;
    private readonly Vector4 MieSct = new Vector4(2.0f, 2.0f, 2.0f, 0.0f) * 0.00001f;
    private void Start()
    {
        _material = new Material(_shader);
        _material.hideFlags = HideFlags.HideAndDontSave;
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(_shader != null)
        {
            var projectionMatrix = GL.GetGPUProjectionMatrix(Camera.current.projectionMatrix, false);
            _material.SetMatrix("_InverseViewMatrix", Camera.current.worldToCameraMatrix.inverse);
            _material.SetMatrix("_InverseProjectionMatrix", projectionMatrix.inverse);
            _material.SetVector("Rtmp", RayleighSct);
            _material.SetVector("Mtmp", MieSct);
            Graphics.Blit(source, destination, _material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
