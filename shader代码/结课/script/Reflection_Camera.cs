using UnityEngine;

public class Reflection_Camera : MonoBehaviour
{
	private Camera _mReflectionCamera;
    private Camera _mMainCamera;

	private RenderTexture _mRenderTarget;
 
	 [SerializeField] private GameObject mReflectionPlane;
	 [SerializeField] private Material mFloorMaterial;
	
	[SerializeField]
	[Range(0f, 1f)]
	private float mReflectionFactor = 0.5f;

	private void Start()
	{
		
		GameObject reflectionCameraGo = new GameObject("ReflectionCamera");
		_mReflectionCamera = reflectionCameraGo.AddComponent<Camera>();
		_mReflectionCamera.enabled = false;
		
 
		_mMainCamera = Camera.main;
		 
		_mRenderTarget = new RenderTexture(Screen.width, Screen.height, 24);
	}
 
	void Update()
	{
		mFloorMaterial.SetFloat("_ReflectionFactor", mReflectionFactor);
	}
 
	void OnPreRender()
	{
		RenderReflection();
	}
 
	void RenderReflection()
	{
		//先复制所有内容
		_mReflectionCamera.CopyFrom(_mMainCamera);
		
		//获取主相机的forward，up和position
		Vector3 cameraDirectionWorldSpace = _mMainCamera.transform.forward;
		Vector3 cameraUpWorldSpace = _mMainCamera.transform.up;
		Vector3 cameraPositionWorldSpace = _mMainCamera.transform.position;
		
		//转换为平面物体的localSpace下的position，forward和up
		Vector3 cameraDirectionPlaneSpace = mReflectionPlane.transform.InverseTransformDirection(cameraDirectionWorldSpace);
		Vector3 cameraUpPlaneSpace = mReflectionPlane.transform.InverseTransformDirection(cameraUpWorldSpace);
		Vector3 cameraPositionPlaneSpace = mReflectionPlane.transform.InverseTransformPoint(cameraPositionWorldSpace);
		
		//逆转
		cameraDirectionPlaneSpace.y *= -1f;
		cameraUpPlaneSpace.y *= -1f;
		cameraPositionPlaneSpace.y *= -1f;
		
		//局部坐标还原到世界坐标
		cameraDirectionWorldSpace = mReflectionPlane.transform.TransformDirection(cameraDirectionPlaneSpace);
		cameraUpWorldSpace = mReflectionPlane.transform.TransformDirection(cameraUpPlaneSpace);
		cameraPositionWorldSpace = mReflectionPlane.transform.TransformPoint(cameraPositionPlaneSpace);
 
		//把新的up，forward和position应用到新的相机上
		_mReflectionCamera.transform.position = cameraPositionWorldSpace;
		_mReflectionCamera.transform.LookAt(cameraPositionWorldSpace + cameraDirectionWorldSpace, cameraUpWorldSpace);
 
		Vector4 viewPlane = CameraSpacePlane(_mReflectionCamera.worldToCameraMatrix, mReflectionPlane.transform.position, mReflectionPlane.transform.up);
		_mReflectionCamera.projectionMatrix = _mReflectionCamera.CalculateObliqueMatrix(viewPlane);
 
		_mReflectionCamera.targetTexture = _mRenderTarget;
		_mReflectionCamera.Render();
 
		mFloorMaterial.SetTexture("_ReflectionTex", _mRenderTarget);
	}
 
	Vector4 CameraSpacePlane(Matrix4x4 worldToCameraMatrix, Vector3 pos, Vector3 normal)
	{
		Vector3 viewPos = worldToCameraMatrix.MultiplyPoint3x4(pos);
		Vector3 viewNormal = worldToCameraMatrix.MultiplyVector(normal).normalized;
		float w = -Vector3.Dot(viewPos, viewNormal);
		return new Vector4(viewNormal.x, viewNormal.y, viewNormal.z, w);
	}
}
