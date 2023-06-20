using UnityEngine;
using System.Collections;
using UnityEngine.Rendering;
using System;
using System.Text;

[ExecuteInEditMode]
#if UNITY_5_4_OR_NEWER
[ImageEffectAllowedInSceneView]
#endif
public class CameraDepth : MonoBehaviour
{
    public float adjust;
    public Shader _ppShader;
    public Material _ppMaterial;

    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
    }

    protected virtual void Start()
    {
        //_InitPPShader();

        /*_ppMaterial = new Material(_ppShader);
        _ppMaterial.hideFlags = HideFlags.HideAndDontSave;*/
    }


    void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
    {
        if (_ppShader != null)
        {
            var projectionMatrix = GL.GetGPUProjectionMatrix(Camera.current.projectionMatrix, false);
            _ppMaterial.SetMatrix("_InverseViewMatrix", Camera.current.worldToCameraMatrix.inverse);
            _ppMaterial.SetMatrix("_InverseProjectionMatrix", projectionMatrix.inverse);
            _ppMaterial.SetFloat("_PosAdjust", adjust);
            Graphics.Blit(sourceTexture, destTexture, _ppMaterial);
        }
        else
        {
            Graphics.Blit(sourceTexture, destTexture);
        }
    }
}