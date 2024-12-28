using System.Collections.Generic;
using UnityEngine;

/*基于CharacterController组件的简单玩家移动控制器，
包含基于当前组件纹理的脚步音效系统*/
public class PlayerController : MonoBehaviour
{
    // 脚步系统的地面图层类
    [System.Serializable]
    public class GroundLayer
    {
        public string layerName; // 图层名称
        public Texture2D[] groundTextures; // 地面纹理数组
        public AudioClip[] footstepSounds; // 对应的脚步音效数组
    }
    
    [Header("Movement")]

    [Tooltip("基础移动速度")]
    [SerializeField] private float walkSpeed;
    
    [Tooltip("奔跑速度倍率")]
    [SerializeField] private float runMultiplier;

    [Tooltip("跳跃力度")]
    [SerializeField] private float jumpForce;

    [Tooltip("重力值，用于跳跃时向下施加力")]
    [SerializeField] private float gravity = -9.81f;

    [Header("Mouse Look")] 
    [SerializeField] private Camera playerCamera; // 玩家摄像机
    [SerializeField] private float mouseSensivity; // 鼠标灵敏度
    [SerializeField] private float mouseVerticalClamp; // 垂直视角限制

    [Header("Keybinds")]
    [SerializeField] private KeyCode jumpKey = KeyCode.Space; // 跳跃按键
    [SerializeField] private KeyCode runKey = KeyCode.LeftShift; // 奔跑按键


    [Header("Footsteps")]
    [Tooltip("脚步音效源")]
    [SerializeField] private AudioSource footstepSource;

    [Tooltip("用于检测地面纹理的距离")]
    [SerializeField] private float groundCheckDistance = 1.0f;

    [Tooltip("脚步音效播放速率")]
    [SerializeField] [Range(1f, 2f)] private float footstepRate = 1f;

    [Tooltip("奔跑时的脚步音效播放速率")]
    [SerializeField] [Range(1f, 2f)] private float runningFootstepRate = 1.5f;

    [Tooltip("为地面图层添加纹理和音效")]
    public List<GroundLayer> groundLayers = new List<GroundLayer>();

    // 私有变量：移动相关
    private float _horizontalMovement;
    private float _verticalMovement;
    private float _currentSpeed;
    private Vector3 _moveDirection;
    private Vector3 _velocity;
    private CharacterController _characterController;
    private bool _isRunning;
    
    // 私有变量：鼠标控制相关
    private float _verticalRotation;
    private float _yAxis;
    private float _xAxis;
    private bool _activeRotation;

    // 私有变量：脚步系统相关
    private Terrain _terrain;
    private TerrainData _terrainData;
    private TerrainLayer[] _terrainLayers;
    private AudioClip _previousClip;
    private Texture2D _currentTexture;
    private RaycastHit _groundHit;
    private float _nextFootstep;
    
    private void Awake()
    {
        _characterController = GetComponent<CharacterController>();
        GetTerrainData(); // 获取地形数据
        Cursor.lockState = CursorLockMode.Locked; // 锁定光标
        Cursor.visible = false; // 隐藏光标
    }

    // 获取地形数据
    private void GetTerrainData()
    {
        if (Terrain.activeTerrain)
        {
            _terrain = Terrain.activeTerrain;
            _terrainData = _terrain.terrainData;
            _terrainLayers = _terrain.terrainData.terrainLayers;
        }
    }

    private void Update()
    {
        Shader.SetGlobalVector("_PlayerPostition", transform.position); // 更新玩家位置到全局Shader变量
        Movement(); // 玩家移动
        MouseLook(); // 鼠标控制视角
        GroundChecker(); // 检测地面纹理
    }

    // 玩家移动控制
    private void Movement()
    {
        // 如果玩家在地面上且垂直速度小于0，重置垂直速度
        if (_characterController.isGrounded && _velocity.y < 0)
        {
            _velocity.y = -2f;
        }
        
        // 跳跃控制
        if (Input.GetKey(jumpKey) && _characterController.isGrounded)
        {
            _velocity.y = Mathf.Sqrt(jumpForce * -2f * gravity);
        }
        
        // 获取移动方向
        _horizontalMovement = Input.GetAxis("Horizontal");
        _verticalMovement = Input.GetAxis("Vertical");
        _moveDirection = transform.forward * _verticalMovement + transform.right * _horizontalMovement;
        
        // 检测是否奔跑
        _isRunning = Input.GetKey(runKey);
        _currentSpeed = walkSpeed * (_isRunning ? runMultiplier : 1f);
        _characterController.Move(_moveDirection * _currentSpeed * Time.deltaTime);

        // 应用重力
        _velocity.y += gravity * Time.deltaTime;
        _characterController.Move(_velocity * Time.deltaTime);
    }

    private void MouseLook()
    {   
        // 鼠标输入
        _xAxis = Input.GetAxis("Mouse X"); 
        _yAxis = Input.GetAxis("Mouse Y");

        // 垂直视角旋转
        _verticalRotation += -_yAxis * mouseSensivity;
        _verticalRotation = Mathf.Clamp(_verticalRotation, -mouseVerticalClamp, mouseVerticalClamp);
        playerCamera.transform.localRotation = Quaternion.Euler(_verticalRotation, 0, 0);

        // 水平视角旋转
        transform.rotation *= Quaternion.Euler(0, _xAxis * mouseSensivity, 0);
    }

    // 检测玩家移动时播放脚步音效
    private void FixedUpdate()
    {
        if (_characterController.isGrounded && (_horizontalMovement != 0 || _verticalMovement != 0))
        {
            float currentFootstepRate = (_isRunning ? runningFootstepRate : footstepRate);

            if (_nextFootstep >= 100f)
            {
                PlayFootstep(); // 播放脚步音效
                _nextFootstep = 0;
            }
            _nextFootstep += (currentFootstepRate * walkSpeed);
        }
    }

    // 检测玩家所在地面的纹理
    private void GroundChecker()
    {
        Ray checkerRay = new Ray(transform.position + (Vector3.up * 0.1f), Vector3.down);

        if (Physics.Raycast(checkerRay, out _groundHit, groundCheckDistance))
        {
            if (_groundHit.collider.GetComponent<Terrain>())
            {
                _currentTexture = _terrainLayers[GetTerrainTexture(transform.position)].diffuseTexture;
            }
            if (_groundHit.collider.GetComponent<Renderer>())
            {
                _currentTexture = GetRendererTexture();
            }
        }
    }

    // 根据纹理播放脚步音效
    private void PlayFootstep()
    {
        for (int i = 0; i < groundLayers.Count; i++)
        {
            for (int k = 0; k < groundLayers[i].groundTextures.Length; k++)
            {
                if (_currentTexture == groundLayers[i].groundTextures[k])
                {
                    footstepSource.PlayOneShot(RandomClip(groundLayers[i].footstepSounds));
                }
            }
        }
    }

    // 根据玩家位置返回地形纹理数组
    private float[] GetTerrainTexturesArray(Vector3 controllerPosition)
    {
        _terrain = Terrain.activeTerrain;
        _terrainData = _terrain.terrainData;
        Vector3 terrainPosition = _terrain.transform.position;

        int positionX = (int)(((controllerPosition.x - terrainPosition.x) / _terrainData.size.x) * _terrainData.alphamapWidth);
        int positionZ = (int)(((controllerPosition.z - terrainPosition.z) / _terrainData.size.z) * _terrainData.alphamapHeight);

        float[,,] layerData = _terrainData.GetAlphamaps(positionX, positionZ, 1, 1);

        float[] texturesArray = new float[layerData.GetUpperBound(2) + 1];
        for (int n = 0; n < texturesArray.Length; ++n)
        {
            texturesArray[n] = layerData[0, 0, n];
        }
        return texturesArray;
    }

    // 返回玩家所在位置的主要纹理索引
    private int GetTerrainTexture(Vector3 controllerPosition)
    {
        float[] array = GetTerrainTexturesArray(controllerPosition);
        float maxArray = 0;
        int maxArrayIndex = 0;

        for (int n = 0; n < array.Length; ++n)
        {

            if (array[n] > maxArray)
            {
                maxArrayIndex = n;
                maxArray = array[n];
            }
        }
        return maxArrayIndex;
    }

    // 返回玩家当前所在物体的主要纹理
    private Texture2D GetRendererTexture()
    {
        var rend = _groundHit.collider.gameObject.GetComponent<Renderer>();
        if (rend == null) return null;

        Texture mainTex = rend.material.mainTexture;
        if (mainTex is Texture2D tex2D)
        {
            return tex2D;
        }
        else
        {
            // mainTexture不是Texture2D类型，可能需要其他处理方式
            return null;
        }
    }

    // 从音效数组中随机选择一个音效，避免连续播放相同音效
    private AudioClip RandomClip(AudioClip[] clips)
    {
        int attempts = 2;
        footstepSource.pitch = Random.Range(0.9f, 1.1f); // 随机音调

        AudioClip selectedClip = clips[Random.Range(0, clips.Length)];

        while (selectedClip == _previousClip && attempts > 0)
        {
            selectedClip = clips[Random.Range(0, clips.Length)];

            attempts--;
        }
        _previousClip = selectedClip;
        return selectedClip;
    }
}

